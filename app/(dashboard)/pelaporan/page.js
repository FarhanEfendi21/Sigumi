"use client"

import { useEffect, useState } from "react"
import { reportService } from "@/services/reportService"
import Link from "next/link"
import { toast } from "sonner"
import { Search, ChevronLeft, ChevronRight, FileText, Pickaxe, Flame, Shield, Leaf, Clock, RefreshCcw, CheckCircle, XCircle, Trash2, MapPin, Eye } from "lucide-react"

const ITEMS_PER_PAGE = 8

const STATUS_OPTIONS = [
  { value: "all", label: "Semua Laporan" },
  { value: "pending", label: "Menunggu" },
  { value: "proses", label: "Dalam Proses" },
  { value: "selesai", label: "Selesai" },
  { value: "ditolak", label: "Ditolak" },
]

const STATUS_STYLES = {
  pending: {
    bg: "bg-amber-50 dark:bg-amber-500/10",
    text: "text-amber-700 dark:text-amber-400",
    border: "border-amber-200 dark:border-amber-500/20",
    dot: "bg-amber-500",
    label: "Menunggu",
    icon: Clock
  },
  proses: {
    bg: "bg-blue-50 dark:bg-blue-500/10",
    text: "text-blue-700 dark:text-blue-400",
    border: "border-blue-200 dark:border-blue-500/20",
    dot: "bg-blue-500",
    label: "Diproses",
    icon: RefreshCcw
  },
  selesai: {
    bg: "bg-emerald-50 dark:bg-emerald-500/10",
    text: "text-emerald-700 dark:text-emerald-400",
    border: "border-emerald-200 dark:border-emerald-500/20",
    dot: "bg-emerald-500",
    label: "Selesai",
    icon: CheckCircle
  },
  ditolak: {
    bg: "bg-red-50 dark:bg-red-500/10",
    text: "text-red-700 dark:text-red-400",
    border: "border-red-200 dark:border-red-500/20",
    dot: "bg-red-500",
    label: "Ditolak",
    icon: XCircle
  },
}

const CATEGORY_STYLES = {
  umum: { style: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300", icon: FileText },
  infrastruktur: { style: "bg-violet-100 text-violet-700 dark:bg-violet-500/20 dark:text-violet-300", icon: Pickaxe },
  bencana: { style: "bg-rose-100 text-rose-700 dark:bg-rose-500/20 dark:text-rose-300", icon: Flame },
  keamanan: { style: "bg-orange-100 text-orange-700 dark:bg-orange-500/20 dark:text-orange-300", icon: Shield },
  lingkungan: { style: "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-300", icon: Leaf },
}

function formatDate(dateStr) {
  if (!dateStr) return null
  const d = new Date(dateStr)
  return d.toLocaleDateString("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  })
}

export default function PelaporanPage() {
  const [reports, setReports] = useState([])
  const [loading, setLoading] = useState(false)
  const [currentPage, setCurrentPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState("all")
  const [search, setSearch] = useState("")

  const fetchData = async () => {
    try {
      setLoading(true)
      const { data, error } = await reportService.getAll()
      if (error) throw error
      setReports(data || [])
    } catch (err) {
      console.error(err)
      toast.error("Gagal mengambil data laporan")
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  // FILTER & SEARCH
  const filtered = reports.filter((r) => {
    const matchStatus = statusFilter === "all" || r.status === statusFilter
    const matchSearch =
      search === "" ||
      r.title?.toLowerCase().includes(search.toLowerCase()) ||
      r.reporter_name?.toLowerCase().includes(search.toLowerCase())
    return matchStatus && matchSearch
  })

  // PAGINATION
  const totalPages = Math.ceil(filtered.length / ITEMS_PER_PAGE)
  const startIdx = (currentPage - 1) * ITEMS_PER_PAGE
  const paginated = filtered.slice(startIdx, startIdx + ITEMS_PER_PAGE)

  useEffect(() => {
    if (currentPage > totalPages && totalPages > 0) {
      setCurrentPage(totalPages)
    }
  }, [filtered.length, totalPages, currentPage])

  useEffect(() => {
    setCurrentPage(1)
  }, [statusFilter, search])

  // DELETE
  const handleDelete = async (id) => {
    if (!confirm("Hapus laporan ini secara permanen?")) return
    try {
      const loadingToast = toast.loading("Memproses penghapusan...")
      await reportService.delete(id)
      toast.dismiss(loadingToast)
      toast.success("Laporan berhasil dihapus")
      fetchData()
    } catch (err) {
      toast.error("Gagal menghapus laporan")
    }
  }

  // UPDATE STATUS
  const handleStatusChange = async (id, newStatus) => {
    try {
      const loadingToast = toast.loading("Memperbarui status...")
      const { error } = await reportService.updateStatus(id, newStatus)
      if (error) throw error
      toast.dismiss(loadingToast)
      toast.success("Status berhasil diperbarui")
      fetchData()
    } catch (err) {
      toast.error("Gagal memperbarui status")
    }
  }

  // Count by status
  const statusCounts = {
    all: reports.length,
    pending: reports.filter((r) => r.status === "pending").length,
    proses: reports.filter((r) => r.status === "proses").length,
    selesai: reports.filter((r) => r.status === "selesai").length,
    ditolak: reports.filter((r) => r.status === "ditolak").length,
  }

  return (
    <div className="min-h-screen p-6 md:p-10 max-w-7xl mx-auto font-sans">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white tracking-tight">
              Pelaporan Warga
            </h1>
            {reports.length > 0 && (
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-gray-100 text-gray-600 dark:bg-white/10 dark:text-gray-300">
                {reports.length} Total
              </span>
            )}
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Monitor dan verifikasi masuknya pesan aduan masyarakat teritorial.
          </p>
        </div>
      </div>

      {/* Stats Board */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {[
          { id: "pending", label: "Menunggu", value: statusCounts.pending, colorClass: "bg-amber-500" },
          { id: "proses", label: "Dalam Proses", value: statusCounts.proses, colorClass: "bg-blue-500" },
          { id: "selesai", label: "Selesai", value: statusCounts.selesai, colorClass: "bg-emerald-500" },
          { id: "ditolak", label: "Ditolak", value: statusCounts.ditolak, colorClass: "bg-red-500" },
        ].map((stat) => (
          <div
            key={stat.label}
            className={`p-5 rounded-xl border border-gray-200 dark:border-white/10 bg-white dark:bg-[#1a1a2e] shadow-sm flex flex-col cursor-pointer transition-all duration-200
               ${statusFilter === stat.id ? 'ring-2 ring-blue-500/50 scale-[1.02]' : 'hover:bg-gray-50 dark:hover:bg-white/5'}
            `}
            onClick={() => setStatusFilter(statusFilter === stat.id ? "all" : stat.id)}
          >
            <div className="flex justify-between items-start mb-2">
              <span className="text-gray-500 dark:text-gray-400 text-xs font-semibold uppercase tracking-wider">{stat.label}</span>
              <div className={`w-2 h-2 rounded-full ${stat.colorClass}`} />
            </div>
            <span className="text-2xl font-bold text-gray-900 dark:text-white">{stat.value}</span>
          </div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="flex flex-col md:flex-row gap-4 mb-6 items-start md:items-center">
        <div className="relative w-full md:w-96 shrink-0">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Cari referensi judul atau pelapor..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2.5 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-black/20 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 outline-none transition-all"
          />
        </div>

        <div className="flex flex-wrap gap-2">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => setStatusFilter(opt.value)}
              className={`px-4 py-2.5 rounded-lg text-xs font-medium transition-colors border
                ${statusFilter === opt.value
                  ? "bg-blue-50 border-blue-200 text-blue-700 dark:bg-blue-500/20 dark:border-blue-500/30 dark:text-blue-400"
                  : "bg-white dark:bg-transparent border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-white/5"
                }`}
            >
              {opt.label} ({statusCounts[opt.value]})
            </button>
          ))}
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-white dark:bg-[#1a1a2e] border border-gray-200 dark:border-white/10 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50/50 dark:bg-white/5 border-b border-gray-200 dark:border-white/10 text-gray-500 dark:text-gray-400 font-medium tracking-wide">
              <tr>
                <th className="px-6 py-4">Tiket Pengaduan</th>
                <th className="px-6 py-4">Kategori & Lokasi</th>
                <th className="px-6 py-4">Status & Waktu</th>
                <th className="px-6 py-4 text-right">Aksi</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-gray-200 dark:divide-white/10">
              {loading ? (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-gray-400">
                    <div className="inline-flex items-center gap-2">
                      <div className="w-4 h-4 border-2 border-gray-300 dark:border-gray-600 border-t-blue-500 rounded-full animate-spin"></div>
                      Memuat data...
                    </div>
                  </td>
                </tr>
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-6 py-16 text-center">
                    <FileText className="w-8 h-8 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                    <p className="text-gray-500 dark:text-gray-400 font-medium">Belum ada dokumen laporan terkait.</p>
                  </td>
                </tr>
              ) : (
                paginated.map((report) => {
                  const status = STATUS_STYLES[report.status] || STATUS_STYLES.pending
                  const catConf = CATEGORY_STYLES[report.category] || CATEGORY_STYLES.umum
                  const CatIcon = catConf.icon

                  return (
                    <tr key={report.id} className="hover:bg-gray-50/50 dark:hover:bg-white/5 transition-colors group">
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1 max-w-[280px]">
                          <span className="font-semibold text-gray-900 dark:text-white truncate">
                            {report.title}
                          </span>
                          <span className="text-xs text-gray-500 dark:text-gray-400">
                            Pelapor: <span className="font-medium text-gray-700 dark:text-gray-300">{report.reporter_name}</span>
                          </span>
                        </div>
                      </td>

                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-2 items-start">
                          <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-medium capitalize ${catConf.style}`}>
                            <CatIcon className="w-3 h-3" /> {report.category}
                          </span>
                          {report.location && (
                            <span className="flex items-center gap-1 text-[11px] text-gray-500 dark:text-gray-400 max-w-[200px] truncate">
                              <MapPin className="w-3 h-3 shrink-0" />
                              <span className="truncate">{report.location}</span>
                            </span>
                          )}
                        </div>
                      </td>

                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-2 items-start max-w-[150px]">
                          <select
                            value={report.status}
                            onChange={(e) => handleStatusChange(report.id, e.target.value)}
                            className={`inline-flex items-center px-2 py-1 rounded-md text-xs font-semibold
                              ${status.bg} ${status.text} border ${status.border}
                              cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500/30 transition-colors
                              appearance-none w-full`}
                          >
                            <option value="pending">Menunggu</option>
                            <option value="proses">Diproses</option>
                            <option value="selesai">Selesai</option>
                            <option value="ditolak">Ditolak</option>
                          </select>
                          <span className="text-[11px] text-gray-400 dark:text-gray-500 font-mono">
                            {formatDate(report.created_at)}
                          </span>
                        </div>
                      </td>

                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <Link href={`/pelaporan/${report.id}`} className="p-1.5 text-blue-600 hover:bg-blue-50 dark:text-blue-400 dark:hover:bg-blue-500/10 rounded transition-colors" title="Lihat Detail">
                            <Eye className="w-4 h-4" />
                          </Link>
                          <button
                            onClick={() => handleDelete(report.id)}
                            className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 rounded transition-colors"
                            title="Hapus"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        {totalPages > 1 && (
          <div className="px-6 py-4 border-t border-gray-200 dark:border-white/10 flex items-center justify-between">
            <span className="text-xs text-gray-500 dark:text-gray-400">
              Menampilkan {startIdx + 1}-{Math.min(startIdx + ITEMS_PER_PAGE, filtered.length)} dari {filtered.length} data
            </span>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                disabled={currentPage === 1}
                className="p-1.5 rounded-md border border-gray-200 dark:border-white/10 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-white/5 disabled:opacity-40 transition-colors"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                disabled={currentPage === totalPages}
                className="p-1.5 rounded-md border border-gray-200 dark:border-white/10 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-white/5 disabled:opacity-40 transition-colors"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>

    </div>
  )
}
