import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

// Import Provider dan Toaster
// Kalo error module not found, ganti pathnya jadi "../components/ThemeProvider"
import { ThemeProvider } from "@/components/ThemeProvider";
import { Toaster } from "sonner";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

// Hapus 'type { Metadata }' murni jadi object JS biasa
export const metadata = {
  title: "SIGUMI - Admin Dashboard",
  description: "Dashboard Project",
};

// Hapus 'Readonly<{ children: React.ReactNode }>' 
export default function RootLayout({ children }) {
  return (
    <html
      lang="en"
      suppressHydrationWarning // 🔥 Wajib ditambahin
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="bg-[#f5f0e6] dark:bg-[#121212] text-gray-800 dark:text-gray-200 min-h-full flex flex-col transition-colors duration-300">

        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
          <Toaster position="top-right" richColors />
        </ThemeProvider>

      </body>
    </html>
  );
}