"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import ThemeToggle from "@/components/ThemeToggle"
import Image from "next/image"
import { LayoutDashboard, Newspaper, Tent, Map, Video, MessageSquare, Users, LogOut, User, MapPin } from "lucide-react"
import { toast } from "sonner"

const menuItems = [
  { href: "/menu", label: "Menu Utama", icon: LayoutDashboard },
  { href: "/news", label: "News", icon: Newspaper },
  { href: "/shelters", label: "Titik Evakuasi", icon: Tent },
  { href: "/tourism", label: "Wisata", icon: Map },
  { href: "/cctv", label: "CCTV Gunung", icon: Video },
  { href: "/pelaporan", label: "Pelaporan Warga", icon: MessageSquare },
  { href: "/users", label: "Users", icon: Users },
]

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const [admin, setAdmin] = useState(null)

  useEffect(() => {
    // Read admin data from localStorage
    const savedAdmin = localStorage.getItem("adminData")
    if (savedAdmin) {
      setAdmin(JSON.parse(savedAdmin))
    }
  }, [])

  const handleLogout = () => {
    localStorage.removeItem("adminData")
    toast.success("Berhasil keluar dari sesi admin")
    router.replace("/login")
  }

  return (
    <aside className="w-64 h-full flex flex-col
      bg-white dark:bg-[#1a1a2e]
      border-r border-gray-200 dark:border-white/5
      transition-colors duration-300 font-sans">

      {/* Logo / Brand */}
      <div className="px-6 py-6 border-b border-gray-200 dark:border-white/10">
        <Link href="/menu" className="flex items-center gap-3">
          <Image
            src="/logo-sigumi.svg"
            alt="Logo Sigumi"
            width={135}
            height={135}
            className="transition-transform duration-300 hover:opacity-80"
          />
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
        <p className="text-[11px] uppercase tracking-wider text-gray-500 dark:text-gray-400 px-3 mb-4 font-semibold">
          Navigasi
        </p>

        {menuItems.map((item) => {
          const isActive =
            item.href === "/menu"
              ? pathname === "/menu" || pathname === "/"
              : pathname.startsWith(item.href)

          const IconComponent = item.icon

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 group relative
                ${isActive
                  ? "bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400"
                  : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/5"
                }`}
            >
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-blue-600 dark:bg-blue-500 rounded-r-full" />
              )}

              <IconComponent className={`w-4 h-4 transition-transform duration-200 ${isActive ? 'stroke-[2.5px]' : 'stroke-2 group-hover:scale-110'}`} />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      {/* Admin Profile & Logout */}
      <div className="mt-auto border-t border-gray-200 dark:border-white/10">
        {admin && (
          <div className="px-5 py-4 border-b border-gray-100 dark:border-white/5">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-9 h-9 rounded-full bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white shrink-0 shadow-lg shadow-blue-500/20">
                <User size={18} />
              </div>
              <div className="flex flex-col min-w-0">
                <span className="text-[13px] font-bold text-gray-900 dark:text-white truncate">
                  {admin.email?.split('@')[0]}
                </span>
                <span className="text-[10px] text-gray-500 dark:text-gray-400 truncate">
                  Administrator
                </span>
              </div>
            </div>
            <div className="flex items-center gap-2 text-[11px] font-bold text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-500/10 px-3 py-1.5 rounded-lg border border-blue-100 dark:border-blue-500/20 w-full justify-center">
              <MapPin size={12} className="shrink-0" />
              <span>Wilayah {admin.lokasi}</span>
            </div>
          </div>
        )}

        {/* Theme & Logout Actions */}
        <div className="px-4 py-3 space-y-2">
          <div className="flex items-center justify-between px-2 py-1.5 rounded-lg bg-gray-50/50 dark:bg-black/10">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">Pilih Tema</span>
            <ThemeToggle compact />
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-2 py-2 text-sm font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors group"
          >
            <LogOut size={16} className="transition-transform group-hover:-translate-x-0.5" />
            <span>Keluar</span>
          </button>
        </div>
      </div>
    </aside>
  )
}