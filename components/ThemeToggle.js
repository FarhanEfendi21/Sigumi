"use client"

import { useTheme } from "next-themes"
import { useEffect, useState } from "react"

export default function ThemeToggle({ compact = false }) {
  const { theme, setTheme, resolvedTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return <div className={compact ? "w-9 h-9" : "w-[100px] h-[38px]"}></div>
  }

  const currentTheme = theme === "system" ? resolvedTheme : theme
  const isDark = currentTheme === "dark"

  if (compact) {
    return (
      <button
        onClick={() => setTheme(isDark ? "light" : "dark")}
        className="relative w-9 h-9 flex items-center justify-center rounded-lg 
          bg-gray-200/80 dark:bg-white/10 
          hover:bg-gray-300 dark:hover:bg-white/20 
          text-gray-600 dark:text-yellow-300
          transition-all duration-300 cursor-pointer"
        title={isDark ? "Switch to Light Mode" : "Switch to Dark Mode"}
      >
        <span className="text-lg transition-transform duration-300 hover:rotate-45">
          {isDark ? "☀️" : "🌙"}
        </span>
      </button>
    )
  }

  return (
    <button
      onClick={() => setTheme(isDark ? "light" : "dark")}
      className="group relative flex items-center gap-2 px-4 py-2 rounded-xl
        bg-gradient-to-r from-gray-100 to-gray-200 dark:from-gray-800 dark:to-gray-700
        border border-gray-200/50 dark:border-gray-600/50
        hover:shadow-lg hover:scale-[1.02]
        text-sm font-medium text-gray-700 dark:text-gray-200
        transition-all duration-300 cursor-pointer"
    >
      <span className="transition-transform duration-500 group-hover:rotate-[360deg]">
        {isDark ? "☀️" : "🌙"}
      </span>
      <span>{isDark ? "Light" : "Dark"}</span>
    </button>
  )
}