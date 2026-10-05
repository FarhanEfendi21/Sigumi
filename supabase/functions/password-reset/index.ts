// Supabase Edge Function: password-reset
// Deno runtime — dijalankan via service_role, tidak ada secret di Flutter client
//
// Endpoint:
//   POST /functions/v1/password-reset
//   Body: { action: string, ...payload }
//
// Actions:
//   "initiate_registration_otp" — kirim OTP verifikasi email saat daftar
//   "verify_registration_otp"   — verifikasi OTP pendaftaran
//   "request_reset"             — minta reset (input nomor telepon)
//   "verify_reset_otp"          — verifikasi OTP reset → terbitkan tiket
//   "set_new_password"          — set kata sandi baru pakai tiket
//   "update_recovery_email"     — ubah email pemulihan (perlu sesi auth)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

// ── Konstanta ────────────────────────────────────────────────
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const EMAIL_FROM = Deno.env.get("EMAIL_FROM") ?? Deno.env.get("SMTP_FROM") ?? "";

const OTP_EXPIRY_MINUTES = 10;
const MAX_OTP_ATTEMPTS = 5;
const RESEND_COOLDOWN_SECONDS = 60;
const MAX_OTP_SENDS_PER_15MIN = 3;
const TICKET_EXPIRY_MINUTES = 10;
const MIN_PASSWORD_LENGTH = 6;

// ── Client Supabase (service_role — server-side saja) ───────
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ── CORS headers ─────────────────────────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ============================================================
// Entry Point
// ============================================================
serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { action } = body;
    const clientIp = getClientIp(req);

    switch (action) {
      case "initiate_registration_otp":
        return await initiateRegistrationOtp(body, clientIp);

      case "verify_registration_otp":
        return await verifyRegistrationOtp(body);

      case "complete_registration":
        return await completeRegistration(body);

      case "request_reset":
        return await requestReset(body, clientIp);

      case "verify_reset_otp":
        return await verifyResetOtp(body);

      case "set_new_password":
        return await setNewPassword(body);

      case "update_recovery_email":
        return await updateRecoveryEmail(body, req);

      default:
        return jsonError("Action tidak valid.", 400);
    }
  } catch (err) {
    console.error("[password-reset] Unhandled error:", err);
    return jsonError("Terjadi kesalahan server.", 500);
  }
});

// ============================================================
// 1. INITIATE REGISTRATION OTP
// Kirim OTP ke email pemulihan sebelum pendaftaran selesai.
// ============================================================
async function initiateRegistrationOtp(
  body: Record<string, string>,
  clientIp: string,
) {
  const email = String(body.email ?? "").trim().toLowerCase();
  const rawPhone = String(body.phone ?? "").trim();
  const phone = normalizePhone(rawPhone);

  if (!email || !isValidEmail(email)) {
    return jsonError("Format email tidak valid.", 400);
  }
  if (!isValidPhone(phone)) {
    return jsonError("Nomor telepon harus disertakan.", 400);
  }

  // Profil dibuat oleh trigger setiap akun SIGUMI berhasil dibuat. Cari akun
  // melalui nomor kanonis di profiles, karena supabase-js v2 tidak menyediakan
  // auth.admin.getUserByEmail(). Respons tetap generik untuk mencegah enumerasi.
  const { data: existingPhoneProfile, error: existingPhoneProfileError } =
    await supabase
      .from("profiles")
      .select("id")
      .eq("phone", phone)
      .limit(1)
      .maybeSingle();

  if (existingPhoneProfileError) {
    console.error("[initiate_registration_otp] Profile lookup failed:", existingPhoneProfileError);
    return jsonError("Gagal memproses permintaan.", 500);
  }
  if (existingPhoneProfile) {
    return jsonOk({ message: "Jika data valid, kode verifikasi akan dikirim." });
  }

  // Cek apakah email sudah dipakai akun lain yang sudah verified
  const { data: existingProfile } = await supabase
    .from("profiles")
    .select("id, recovery_email_verified")
    .ilike("recovery_email", email)
    .eq("recovery_email_verified", true)
    .maybeSingle();

  if (existingProfile) {
    // Respons generik — jangan bocorkan email sudah terdaftar
    return jsonOk({
      message:
        "Jika email valid, instruksi verifikasi akan dikirimkan ke inbox Anda.",
    });
  }

  const registrationWindowStart = new Date(
    Date.now() - 15 * 60 * 1000,
  ).toISOString();
  const { count: recentPhoneChallenges } = await supabase
    .from("otp_challenges")
    .select("id", { count: "exact", head: true })
    .eq("purpose", "registration")
    .eq("target_phone", phone)
    .gte("created_at", registrationWindowStart);
  const { count: recentEmailChallenges } = await supabase
    .from("otp_challenges")
    .select("id", { count: "exact", head: true })
    .eq("purpose", "registration")
    .eq("target_email", email)
    .gte("created_at", registrationWindowStart);

  if (
    (recentPhoneChallenges ?? 0) >= MAX_OTP_SENDS_PER_15MIN ||
    (recentEmailChallenges ?? 0) >= MAX_OTP_SENDS_PER_15MIN
  ) {
    return jsonError(
      "Batas pengiriman kode tercapai. Silakan coba lagi dalam 15 menit.",
      429,
    );
  }

  // Cek rate limit per IP (20 per jam)
  const ipRateOk = await checkIpRateLimit(clientIp, "registration");
  if (!ipRateOk) {
    return jsonError(
      "Terlalu banyak permintaan. Silakan coba beberapa saat lagi.",
      429,
    );
  }

  // Hanya kode terbaru yang berlaku untuk pasangan email + nomor ini.
  await supabase
    .from("otp_challenges")
    .update({ consumed_at: new Date().toISOString() })
    .eq("purpose", "registration")
    .eq("target_email", email)
    .eq("target_phone", phone)
    .is("consumed_at", null);

  // Generate OTP
  const otp = generateOtp();
  const otpHash = await sha256(otp);
  const expiresAt = new Date(
    Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000,
  ).toISOString();

  // Simpan challenge (tanpa user_id karena belum ada akun)
  const { error: insertError } = await supabase
    .from("otp_challenges")
    .insert({
      user_id: null,
      purpose: "registration",
      otp_hash: otpHash,
      target_email: email,
      target_phone: phone,
      request_ip: clientIp,
      expires_at: expiresAt,
    });

  if (insertError) {
    console.error("[initiate_registration_otp] DB error:", insertError);
    return jsonError("Gagal memproses permintaan.", 500);
  }

  const emailSent = await sendOtpEmail(email, otp, "registration");
  if (!emailSent) {
    await supabase
      .from("otp_challenges")
      .update({ consumed_at: new Date().toISOString() })
      .eq("purpose", "registration")
      .eq("target_email", email)
      .eq("target_phone", phone)
      .is("consumed_at", null);
    return jsonError("Email verifikasi gagal dikirim. Silakan coba lagi nanti.", 502);
  }

  // Selalu respons generik
  return jsonOk({
    message:
      "Jika email valid, instruksi verifikasi akan dikirimkan ke inbox Anda.",
  });
}

// ============================================================
// 2. VERIFY REGISTRATION OTP
// Verifikasi kode yang dikirim saat daftar.
// Mengembalikan user_id yang bisa dipakai untuk menyelesaikan signup.
// ============================================================
async function verifyRegistrationOtp(body: Record<string, string>) {
  const email = String(body.email ?? "").trim().toLowerCase();
  const otp = String(body.otp ?? "").trim();
  const phone = normalizePhone(String(body.phone ?? "").trim());

  if (!email || !otp || !phone) {
    return jsonError("Parameter tidak lengkap.", 400);
  }
  if (!isValidPhone(phone) || !/^\d{6}$/.test(otp) || !isValidEmail(email)) {
    return jsonError("Parameter tidak valid.", 400);
  }

  const otpHash = await sha256(otp.trim());

  // Ambil challenge terbaru yang aktif untuk email ini
  const { data: challenge } = await supabase
    .from("otp_challenges")
    .select("*")
    .eq("purpose", "registration")
    .eq("target_email", email)
    .eq("target_phone", phone)
    .is("consumed_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!challenge) {
    return jsonError("Kode tidak ditemukan atau sudah kedaluwarsa.", 400);
  }

  // Cek expiry
  if (new Date(challenge.expires_at) < new Date()) {
    return jsonError("Kode sudah kedaluwarsa. Minta kode baru.", 400);
  }

  // Cek max attempts
  if (challenge.attempts >= challenge.max_attempts) {
    return jsonError(
      "Batas percobaan tercapai. Minta kode baru untuk melanjutkan.",
      429,
    );
  }

  // Optimistic atomic increment mencegah dua verifikasi paralel melewati limit.
  const { data: attemptUpdate } = await supabase
    .from("otp_challenges")
    .update({ attempts: challenge.attempts + 1 })
    .eq("id", challenge.id)
    .eq("attempts", challenge.attempts)
    .is("consumed_at", null)
    .select("id")
    .maybeSingle();

  if (!attemptUpdate) {
    return jsonError("Kode tidak valid atau sudah digunakan. Minta kode baru.", 400);
  }

  // Verifikasi OTP
  if (challenge.otp_hash !== otpHash) {
    const remaining = challenge.max_attempts - challenge.attempts - 1;
    return jsonError(
      `Kode tidak sesuai. ${remaining > 0 ? `Sisa percobaan: ${remaining}.` : "Batas percobaan tercapai."}`,
      400,
    );
  }

  // OTP valid — konsumsi satu kali, lalu terbitkan token pendaftaran.
  const { data: consumedChallenge } = await supabase
    .from("otp_challenges")
    .update({ consumed_at: new Date().toISOString() })
    .eq("id", challenge.id)
    .is("consumed_at", null)
    .select("id")
    .maybeSingle();

  if (!consumedChallenge) {
    return jsonError("Kode tidak valid atau sudah digunakan. Minta kode baru.", 400);
  }

  const registrationToken = crypto.randomUUID();
  const { data: grant, error: grantError } = await supabase
    .from("registration_email_verifications")
    .insert({
      token_hash: await sha256(registrationToken),
      target_phone: phone,
      target_email: email,
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    })
    .select("id")
    .single();

  if (grantError || !grant) {
    console.error("[verify_registration_otp] Grant creation failed:", grantError);
    return jsonError("Gagal memproses verifikasi. Silakan minta kode baru.", 500);
  }

  return jsonOk({
    verified: true,
    registration_token: registrationToken,
    message: "Email pemulihan berhasil diverifikasi.",
  });
}

// ============================================================
// 2b. COMPLETE REGISTRATION
// Hanya endpoint server ini yang membuat akun SIGUMI baru. Trigger DB
// mengonsumsi grant yang ditandatangani server dan menyimpan email verified.
// ============================================================
async function completeRegistration(body: Record<string, string>) {
  const registrationToken = String(body.registration_token ?? "").trim();
  const phone = normalizePhone(String(body.phone ?? ""));
  const password = String(body.password ?? "");
  const fullName = String(body.full_name ?? "").trim();
  const dateOfBirth = String(body.date_of_birth ?? "").trim();

  if (!registrationToken || !isValidPhone(phone) || !password || !fullName) {
    return jsonError("Data pendaftaran belum lengkap.", 400);
  }
  if (password.length < MIN_PASSWORD_LENGTH) {
    return jsonError(`Kata sandi minimal ${MIN_PASSWORD_LENGTH} karakter.`, 400);
  }
  if (fullName.length > 120 || password.length > 256) {
    return jsonError("Data pendaftaran tidak valid.", 400);
  }
  if (dateOfBirth && !/^\d{4}-\d{2}-\d{2}$/.test(dateOfBirth)) {
    return jsonError("Tanggal lahir tidak valid.", 400);
  }

  const { data: grant, error: grantLookupError } = await supabase
    .from("registration_email_verifications")
    .select("id, target_phone, expires_at, consumed_at")
    .eq("token_hash", await sha256(registrationToken))
    .eq("target_phone", phone)
    .is("consumed_at", null)
    .maybeSingle();

  if (grantLookupError || !grant || new Date(grant.expires_at) < new Date()) {
    return jsonError("Verifikasi pendaftaran tidak valid atau kedaluwarsa. Verifikasi email kembali.", 400);
  }

  const syntheticEmail = phoneToEmail(phone);
  const { data: created, error: createError } = await supabase.auth.admin.createUser({
    email: syntheticEmail,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      phone,
      // Supabase Auth inserts user_metadata before firing on_auth_user_created.
      // app_metadata is applied later in the same transaction, so the trigger
      // cannot read a registration grant from raw_app_meta_data at INSERT time.
      sigumi_registration_grant_id: grant.id,
      ...(dateOfBirth ? { date_of_birth: dateOfBirth } : {}),
    },
  });

  if (createError || !created.user) {
    console.error("[complete_registration] Account creation failed:", createError?.message);
    return jsonError("Pendaftaran gagal. Periksa data Anda atau verifikasi email kembali.", 400);
  }

  return jsonOk({
    registered: true,
    message: "Pendaftaran berhasil. Silakan masuk menggunakan nomor telepon.",
  });
}

// ============================================================
// 3. REQUEST RESET
// Terima nomor telepon, cari email pemulihan, kirim OTP.
// Selalu respons generik untuk mencegah enumerasi akun.
// ============================================================
async function requestReset(body: Record<string, string>, clientIp: string) {
  const { phone } = body;

  if (!phone) {
    return jsonGenericResetResponse();
  }

  // Rate limit per IP
  const ipRateOk = await checkIpRateLimit(clientIp, "reset");
  if (!ipRateOk) {
    // Tetap respons generik — jangan bocorkan rate limit
    return jsonGenericResetResponse();
  }

  // Lookup profil memakai nomor telepon kanonis; profil selalu terhubung ke
  // auth.users melalui foreign key.
  const normalizedPhone = normalizePhone(phone);
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, recovery_email, recovery_email_verified")
    .eq("phone", normalizedPhone)
    .limit(1)
    .maybeSingle();

  if (profileError) {
    console.error("[request_reset] Profile lookup failed:", profileError);
    await randomDelay();
    return jsonGenericResetResponse();
  }

  if (!profile) {
    // Akun tidak ada — respons generik, tapi tambahkan delay kecil
    await randomDelay();
    return jsonGenericResetResponse();
  }

  const userId = profile.id;

  // Cek apakah user punya email pemulihan terverifikasi
  if (!profile?.recovery_email || !profile.recovery_email_verified) {
    await randomDelay();
    return jsonGenericResetResponse();
  }

  const recoveryEmail = profile.recovery_email;

  // Cek rate limit per akun (3 per 15 menit)
  const accountRateOk = await checkAccountOtpRateLimit(userId, "reset");
  if (!accountRateOk) {
    await randomDelay();
    return jsonGenericResetResponse();
  }

  // Cek cooldown kirim ulang (60 detik)
  const cooldownOk = await checkResendCooldown(userId, "reset");
  if (!cooldownOk) {
    return jsonError(
      "Silakan tunggu 60 detik sebelum meminta kode baru.",
      429,
    );
  }

  // Generate OTP
  const otp = generateOtp();
  const otpHash = await sha256(otp);
  const expiresAt = new Date(
    Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000,
  ).toISOString();

  const { error: insertError } = await supabase
    .from("otp_challenges")
    .insert({
      user_id: userId,
      purpose: "reset",
      otp_hash: otpHash,
      target_email: recoveryEmail,
      request_ip: clientIp,
      expires_at: expiresAt,
    });

  if (insertError) {
    console.error("[request_reset] DB error:", insertError);
    await randomDelay();
    return jsonGenericResetResponse();
  }

  const emailSent = await sendOtpEmail(recoveryEmail, otp, "reset");
  if (!emailSent) {
    await supabase
      .from("otp_challenges")
      .update({ consumed_at: new Date().toISOString() })
      .eq("user_id", userId)
      .eq("purpose", "reset")
      .eq("target_email", recoveryEmail)
      .is("consumed_at", null);
  }

  return jsonGenericResetResponse();
}

// ============================================================
// 4. VERIFY RESET OTP
// Verifikasi OTP reset → terbitkan tiket sekali pakai.
// ============================================================
async function verifyResetOtp(body: Record<string, string>) {
  const { phone, otp } = body;

  if (!phone || !otp) {
    return jsonError("Parameter tidak lengkap.", 400);
  }

  const normalizedPhone = normalizePhone(phone);
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id")
    .eq("phone", normalizedPhone)
    .limit(1)
    .maybeSingle();

  if (profileError || !profile) {
    if (profileError) {
      console.error("[verify_reset_otp] Profile lookup failed:", profileError);
    }
    return jsonError("Kode tidak valid atau sudah kedaluwarsa.", 400);
  }

  const userId = profile.id;
  const otpHash = await sha256(otp.trim());

  // Cari challenge reset aktif
  const { data: challenge } = await supabase
    .from("otp_challenges")
    .select("*")
    .eq("user_id", userId)
    .eq("purpose", "reset")
    .is("consumed_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!challenge) {
    return jsonError("Kode tidak ditemukan atau sudah kedaluwarsa.", 400);
  }

  if (new Date(challenge.expires_at) < new Date()) {
    return jsonError("Kode sudah kedaluwarsa. Minta kode baru.", 400);
  }

  if (challenge.attempts >= challenge.max_attempts) {
    return jsonError(
      "Batas percobaan tercapai. Minta kode baru untuk melanjutkan.",
      429,
    );
  }

  // Increment attempts
  await supabase
    .from("otp_challenges")
    .update({ attempts: challenge.attempts + 1 })
    .eq("id", challenge.id);

  if (challenge.otp_hash !== otpHash) {
    const remaining = challenge.max_attempts - challenge.attempts - 1;
    return jsonError(
      `Kode tidak sesuai. ${remaining > 0 ? `Sisa percobaan: ${remaining}.` : "Batas percobaan tercapai."}`,
      400,
    );
  }

  // OTP valid — konsumsi challenge
  await supabase
    .from("otp_challenges")
    .update({ consumed_at: new Date().toISOString() })
    .eq("id", challenge.id);

  // Terbitkan tiket reset
  const ticket = crypto.randomUUID();
  const ticketHash = await sha256(ticket);
  const ticketExpiresAt = new Date(
    Date.now() + TICKET_EXPIRY_MINUTES * 60 * 1000,
  ).toISOString();

  const { error: ticketError } = await supabase.from("reset_tickets").insert({
    user_id: userId,
    challenge_id: challenge.id,
    ticket_hash: ticketHash,
    expires_at: ticketExpiresAt,
  });

  if (ticketError) {
    console.error("[verify_reset_otp] Ticket insert error:", ticketError);
    return jsonError("Gagal memproses verifikasi.", 500);
  }

  return jsonOk({
    verified: true,
    reset_ticket: ticket, // dikirim ke client, hanya sekali
    expires_in_seconds: TICKET_EXPIRY_MINUTES * 60,
  });
}

// ============================================================
// 5. SET NEW PASSWORD
// Validasi tiket dan ubah kata sandi via service_role.
// ============================================================
async function setNewPassword(body: Record<string, string>) {
  const { reset_ticket, new_password } = body;

  if (!reset_ticket || !new_password) {
    return jsonError("Parameter tidak lengkap.", 400);
  }

  if (new_password.length < MIN_PASSWORD_LENGTH) {
    return jsonError(
      `Kata sandi minimal ${MIN_PASSWORD_LENGTH} karakter.`,
      400,
    );
  }

  const ticketHash = await sha256(reset_ticket);

  // Cari tiket aktif
  const { data: ticket } = await supabase
    .from("reset_tickets")
    .select("*")
    .eq("ticket_hash", ticketHash)
    .is("consumed_at", null)
    .maybeSingle();

  if (!ticket) {
    return jsonError("Sesi reset tidak valid atau sudah kedaluwarsa.", 400);
  }

  if (new Date(ticket.expires_at) < new Date()) {
    return jsonError(
      "Sesi reset sudah kedaluwarsa. Ulangi proses dari awal.",
      400,
    );
  }

  const userId = ticket.user_id;

  // Konsumsi tiket dahulu (atomik) sebelum ubah kata sandi
  const { error: consumeError } = await supabase
    .from("reset_tickets")
    .update({ consumed_at: new Date().toISOString() })
    .eq("id", ticket.id)
    .is("consumed_at", null); // double-check atomic

  if (consumeError) {
    console.error("[set_new_password] Consume ticket error:", consumeError);
    return jsonError("Sesi reset tidak valid.", 400);
  }

  // Ubah kata sandi via Admin API
  const { error: updateError } = await supabase.auth.admin.updateUserById(
    userId,
    { password: new_password },
  );

  if (updateError) {
    console.error("[set_new_password] Password update error:", updateError);
    // Tiket sudah dikonsumsi — jangan biarkan retry dengan tiket yang sama
    return jsonError(
      "Gagal memperbarui kata sandi. Ulangi proses reset dari awal.",
      500,
    );
  }

  console.log(
    `[set_new_password] Password berhasil diubah untuk user: ${userId}`,
  );

  return jsonOk({
    success: true,
    message: "Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru.",
  });
}

// ============================================================
// 6. UPDATE RECOVERY EMAIL (Dari Profil — butuh sesi auth)
// ============================================================
async function updateRecoveryEmail(
  body: Record<string, string>,
  req: Request,
) {
  const new_email = String(body.new_email ?? "").trim().toLowerCase();
  const otp = String(body.otp ?? "").trim();
  const phase = String(body.phase ?? "");
  const authHeader = req.headers.get("authorization");

  if (!authHeader) {
    return jsonError("Autentikasi diperlukan.", 401);
  }

  // Verifikasi token pengguna yang sedang login
  const token = authHeader.replace("Bearer ", "");
  const { data: userData, error: userError } =
    await supabase.auth.getUser(token);

  if (userError || !userData.user) {
    return jsonError("Sesi tidak valid.", 401);
  }

  const userId = userData.user.id;
  const clientIp = getClientIp(req);

  if (phase === "initiate") {
    // Fase 1: Kirim OTP ke email baru
    if (!new_email || !isValidEmail(new_email)) {
      return jsonError("Format email tidak valid.", 400);
    }

    if (!(await checkIpRateLimit(clientIp, "change_email"))) {
      return jsonError("Terlalu banyak permintaan. Silakan coba lagi nanti.", 429);
    }

    const { data: existingEmailOwner } = await supabase
      .from("profiles")
      .select("id")
      .ilike("recovery_email", new_email)
      .eq("recovery_email_verified", true)
      .neq("id", userId)
      .maybeSingle();
    if (existingEmailOwner) {
      return jsonError("Email tersebut sudah digunakan sebagai email pemulihan.", 409);
    }

    const cooldownOk = await checkResendCooldown(userId, "change_email");
    if (!cooldownOk) {
      return jsonError("Tunggu 60 detik sebelum meminta kode baru.", 429);
    }

    const otp = generateOtp();
    const otpHash = await sha256(otp);
    const expiresAt = new Date(
      Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000,
    ).toISOString();

    const { data: challenge, error: insertError } = await supabase.from("otp_challenges").insert({
      user_id: userId,
      purpose: "change_email",
      otp_hash: otpHash,
      target_email: new_email,
      request_ip: clientIp,
      expires_at: expiresAt,
    }).select("id").single();

    if (insertError || !challenge) {
      console.error("[update_recovery_email] Challenge insert failed:", insertError);
      return jsonError("Gagal memproses permintaan. Silakan coba lagi.", 500);
    }

    const emailSent = await sendOtpEmail(new_email, otp, "change_email");
    if (!emailSent) {
      await supabase
        .from("otp_challenges")
        .update({ consumed_at: new Date().toISOString() })
        .eq("id", challenge.id)
        .is("consumed_at", null);
      return jsonError("Email verifikasi gagal dikirim. Silakan coba lagi nanti.", 502);
    }

    return jsonOk({ message: "Kode verifikasi dikirim ke email baru." });
  } else if (phase === "verify") {
    // Fase 2: Verifikasi OTP dan perbarui email pemulihan
    if (!new_email || !otp) {
      return jsonError("Parameter tidak lengkap.", 400);
    }

    const otpHash = await sha256(otp.trim());

    const { data: challenge } = await supabase
      .from("otp_challenges")
      .select("*")
      .eq("user_id", userId)
      .eq("purpose", "change_email")
      .eq("target_email", new_email)
      .is("consumed_at", null)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!challenge) {
      return jsonError("Kode tidak ditemukan atau sudah kedaluwarsa.", 400);
    }

    if (new Date(challenge.expires_at) < new Date()) {
      return jsonError("Kode sudah kedaluwarsa.", 400);
    }

    if (challenge.attempts >= challenge.max_attempts) {
      return jsonError("Batas percobaan tercapai.", 429);
    }

    await supabase
      .from("otp_challenges")
      .update({ attempts: challenge.attempts + 1 })
      .eq("id", challenge.id);

    if (challenge.otp_hash !== otpHash) {
      const remaining = challenge.max_attempts - challenge.attempts - 1;
      return jsonError(
        `Kode tidak sesuai. ${remaining > 0 ? `Sisa percobaan: ${remaining}.` : "Batas percobaan tercapai."}`,
        400,
      );
    }

    await supabase
      .from("otp_challenges")
      .update({ consumed_at: new Date().toISOString() })
      .eq("id", challenge.id);

    const { error: profileUpdateError } = await supabase
      .from("profiles")
      .update({
        recovery_email: new_email,
        recovery_email_verified: true,
        recovery_email_verified_at: new Date().toISOString(),
      })
      .eq("id", userId);

    if (profileUpdateError) {
      console.error("[update_recovery_email] Profile update failed:", profileUpdateError);
      return jsonError("Email terverifikasi, tetapi profil gagal diperbarui. Kirim kode verifikasi baru.", 500);
    }

    return jsonOk({ success: true, message: "Email pemulihan berhasil diperbarui." });
  }

  return jsonError("Phase tidak valid. Gunakan 'initiate' atau 'verify'.", 400);
}

// ============================================================
// HELPERS
// ============================================================

function generateOtp(): string {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return String(array[0] % 1000000).padStart(6, "0");
}

async function sha256(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidPhone(phone: string): boolean {
  return /^\+62\d{8,13}$/.test(phone);
}

function phoneToEmail(phone: string): string {
  const digits = phone.replace(/\D/g, "");
  return `${digits}@sigumi.app`;
}

function normalizePhone(phone: string): string {
  let cleaned = phone.replace(/[\s\-\(\)]/g, "");
  if (cleaned.startsWith("0")) {
    cleaned = "+62" + cleaned.substring(1);
  } else if (cleaned.startsWith("62")) {
    cleaned = "+" + cleaned;
  } else if (!cleaned.startsWith("+")) {
    cleaned = "+62" + cleaned;
  }
  return cleaned;
}

async function randomDelay(): Promise<void> {
  const ms = 200 + Math.random() * 300;
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function checkIpRateLimit(
  ip: string,
  purpose: string,
): Promise<boolean> {
  // Mengandalkan reverse proxy VPS untuk menetapkan X-Forwarded-For.
  const { count } = await supabase
    .from("otp_challenges")
    .select("*", { count: "exact", head: true })
    .eq("purpose", purpose)
    .eq("request_ip", ip)
    .gte("created_at", new Date(Date.now() - 60 * 60 * 1000).toISOString())

  return (count ?? 0) < 20;
}

function getClientIp(req: Request): string {
  const forwardedFor = req.headers.get("x-forwarded-for");
  return forwardedFor?.split(",")[0].trim() || "unknown";
}

async function checkAccountOtpRateLimit(
  userId: string,
  purpose: string,
): Promise<boolean> {
  const { count } = await supabase
    .from("otp_challenges")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("purpose", purpose)
    .gte(
      "created_at",
      new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    );

  return (count ?? 0) < MAX_OTP_SENDS_PER_15MIN;
}

async function checkResendCooldown(
  userId: string,
  purpose: string,
): Promise<boolean> {
  const { data: latest } = await supabase
    .from("otp_challenges")
    .select("created_at")
    .eq("user_id", userId)
    .eq("purpose", purpose)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!latest) return true;

  const elapsed =
    (Date.now() - new Date(latest.created_at).getTime()) / 1000;
  return elapsed >= RESEND_COOLDOWN_SECONDS;
}

async function sendOtpEmail(
  to: string,
  otp: string,
  purpose: "registration" | "reset" | "change_email",
): Promise<boolean> {
  try {
    if (!RESEND_API_KEY || !EMAIL_FROM) {
      console.error("[sendOtpEmail] Email provider belum dikonfigurasi.");
      return false;
    }

    const purposeText: Record<string, string> = {
      registration: "verifikasi email pendaftaran",
      reset: "reset kata sandi",
      change_email: "perubahan email pemulihan",
    };

    const subject =
      purpose === "reset"
        ? "SIGUMI — Kode Reset Kata Sandi"
        : "SIGUMI — Kode Verifikasi Email";

    const html = `
<!DOCTYPE html>
<html lang="id">
<head><meta charset="utf-8"><title>${subject}</title></head>
<body style="font-family:Arial,sans-serif;background:#f5f5f5;padding:24px">
  <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:12px;padding:32px;box-shadow:0 2px 8px rgba(0,0,0,0.08)">
    <div style="text-align:center;margin-bottom:24px">
      <h1 style="color:#1A2B6D;font-size:24px;margin:0">SIGUMI</h1>
      <p style="color:#666;font-size:13px;margin:4px 0 0">Sistem Informasi Gunung Berapi Indonesia</p>
    </div>
    <h2 style="color:#1E1E2C;font-size:18px">Kode ${purposeText[purpose]}</h2>
    <p style="color:#4B5563;font-size:14px;line-height:1.6">
      Gunakan kode berikut untuk ${purposeText[purpose]} Anda:
    </p>
    <div style="background:#EEF2FF;border-radius:10px;padding:20px;text-align:center;margin:20px 0">
      <span style="font-size:36px;font-weight:700;letter-spacing:8px;color:#1A2B6D">${otp}</span>
    </div>
    <p style="color:#6B7280;font-size:13px;line-height:1.6">
      Kode ini berlaku selama <strong>${OTP_EXPIRY_MINUTES} menit</strong>.
      Jangan bagikan kode ini kepada siapa pun, termasuk tim SIGUMI.
    </p>
    <hr style="border:none;border-top:1px solid #E5E7EB;margin:24px 0">
    <p style="color:#9CA3AF;font-size:12px;text-align:center">
      Jika Anda tidak meminta kode ini, abaikan email ini.
    </p>
  </div>
</body>
</html>`;

    const emailPayload = {
      from: EMAIL_FROM,
      to: [to],
      subject,
      html,
    };

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(emailPayload),
    });

    if (!response.ok) {
      console.error(`[sendOtpEmail] Provider returned ${response.status}.`);
      return false;
    }

    return true;
  } catch (err) {
    console.error("[sendOtpEmail] Error:", err);
    return false;
  }
}

function jsonGenericResetResponse(): Response {
  return jsonOk({
    message:
      "Jika akun memiliki email pemulihan terverifikasi, instruksi akan dikirimkan.",
  });
}

function jsonOk(data: Record<string, unknown>): Response {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
