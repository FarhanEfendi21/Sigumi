"use client"

import { useEffect, useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { userService } from "@/services/userService"
import { toast } from "sonner"
import Link from "next/link"
import { ArrowLeft, UserCog, Save } from "lucide-react"

export default function EditUserPage() {
  const params = useParams()
  const router = useRouter()

  const [fullName, setFullName] = useState("")
  const [loading, setLoading] = useState(false)
  const [fetching, setFetching] = useState(true)

  useEffect(() => {
    const fetchUser = async () => {
      try {
        setFetching(true)
        const { data, error } = await userService.getById(params.id)
        if (error) throw error
        if (data) {
          setFullName(data.full_name || "")
        }
      } catch (err) {
        console.error(err)
        toast.error("Gagal mengambil data user")
      } finally {
        setFetching(false)
      }
    }

    if (params.id) fetchUser()
  }, [params.id])

  const handleSubmit = async (e) => {
    e.preventDefault()

    try {
      setLoading(true)
      const loadingToast = toast.loading("Menyimpan perubahan...")

      const { error } = await userService.update(params.id, {
        full_name: fullName,
      })

      if (error) throw error

      toast.dismiss(loadingToast)
      toast.success("Data pengguna berhasil diperbarui")

      setTimeout(() => {
        router.push("/users")
      }, 1200)
    } catch (err) {
      console.error(err)
      toast.error("Terjadi kesalahan sistem")
    } finally {
      setLoading(false)
    }
  }

  if (fetching) {
    return (
      <div className="min-h-screen p-6 md:p-10 flex items-center justify-center font-sans">
        <div className="flex items-center gap-3 text-gray-500">
          <div className="w-5 h-5 border-2 border-gray-300 dark:border-gray-600 border-t-blue-500 rounded-full animate-spin"></div>
          <span className="text-sm font-medium">Memuat data profil...</span>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen p-6 md:p-10 font-sans">
      <div className="max-w-2xl mx-auto">
        
        {/* Back Navigation */}
        <Link
          href="/users"
          className="inline-flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white font-medium transition-colors mb-6"
        >
          <ArrowLeft className="w-4 h-4" />
          Kembali ke Daftar Pengguna
        </Link>

        {/* Page Header */}
        <div className="mb-6 flex gap-3 items-center">
          <div className="p-3 bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-400 rounded-xl border border-blue-100 dark:border-blue-500/20">
            <UserCog className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white tracking-tight">
              Edit Pengguna
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">
              Kelola informasi profil akun terpilih.
            </p>
          </div>
        </div>

        {/* Form Card */}
        <form onSubmit={handleSubmit} className="bg-white dark:bg-[#1a1a2e] rounded-xl shadow-sm border border-gray-200 dark:border-white/10 overflow-hidden">
          
          <div className="p-6 md:p-8 space-y-6">
            <div className="space-y-1.5">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                Nama Lengkap
                </label>
                <input
                className="w-full px-4 py-2.5 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-black/20 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all duration-200 text-sm"
                placeholder="Masukkan nama identitas..."
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                required
                />
            </div>
            {/* Displaying ID just as reference, disabled */}
            <div className="space-y-1.5">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-300">
                System ID
                </label>
                <input
                disabled
                className="w-full px-4 py-2.5 rounded-lg border border-gray-100 dark:border-white/5 bg-gray-50 dark:bg-white/5 text-gray-500 dark:text-gray-400 font-mono text-xs cursor-not-allowed"
                value={params.id}
                />
            </div>
          </div>

          {/* Action Footer */}
          <div className="px-6 py-4 bg-gray-50 dark:bg-black/20 border-t border-gray-200 dark:border-white/10 flex justify-end gap-3">
            <button
                type="button"
                onClick={() => router.push("/users")}
                className="px-5 py-2.5 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-white/5 transition-colors"
            >
                Batal
            </button>
            <button
                type="submit"
                disabled={loading}
                className="inline-flex items-center gap-2 px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium disabled:opacity-50 transition-colors focus:ring-4 focus:ring-blue-500/20"
            >
                {loading ? (
                    <>Menyimpan...</>
                ) : (
                    <><Save className="w-4 h-4"/> Simpan Perubahan</>
                )}
            </button>
         </div>
        </form>

      </div>
    </div>
  )
}
