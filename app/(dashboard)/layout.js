"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import Sidebar from "@/components/layout/sidebar"
import { Loader2 } from "lucide-react"

export default function Layout({ children }) {
  const router = useRouter()
  const [isAuthorized, setIsAuthorized] = useState(false)

  useEffect(() => {
    const adminData = localStorage.getItem("adminData")
    
    if (!adminData) {
      router.replace("/login")
    } else {
      setIsAuthorized(true)
    }
  }, [router])

  if (!isAuthorized) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-[#f5f0e6] dark:bg-[#0f0f1a]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="h-10 w-10 animate-spin text-blue-600" />
          <p className="text-gray-500 dark:text-gray-400 font-medium">Memverifikasi Sesi...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <main className="flex-1 overflow-y-auto
        bg-[#f5f0e6] dark:bg-[#0f0f1a]
        transition-colors duration-300">
        {children}
      </main>
    </div>
  )
}