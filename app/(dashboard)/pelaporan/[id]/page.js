"use client"

import { useEffect, useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { reportService } from "@/services/reportService"
import { toast } from "sonner"
import Link from "next/link"
import { ArrowLeft, MapPin, Phone, Calendar, Clock, RefreshCcw, CheckCircle, XCircle, Trash2, CameraOff } from "lucide-react"

const STATUS_OPTIONS = [
  { value: "pending", label: "Menunggu", icon: Clock },
  { value: "proses", label: "Diproses", icon: RefreshCcw },
  { value: "selesai", label: "Selesai", icon: CheckCircle },
  { value: "ditolak", label: "Ditolak", icon: XCircle },
]

const STATUS_STYLES = {
  pending: {
    bg: "bg-amber-100 dark:bg-amber-500/20",
    text: "text-amber-700 dark:text-amber-400",
    label: "Menunggu",
  },
  proses: {
    bg: "bg-blue-100 dark:bg-blue-500/20",
    text: "text-blue-700 dark:text-blue-400",
    label: "Dalam Proses",
  },
  selesai: {
    bg: "bg-emerald-100 dark:bg-emerald-500/20",
    text: "text-emerald-700 dark:text-emerald-400",
    label: "Selesai",
  },
  ditolak: {
    bg: "bg-red-100 dark:bg-red-500/20",
    text: "text-red-700 dark:text-red-400",
    label: "Ditolak",
  },
}

function formatDate(dateStr) {
  if (!dateStr) return null
  const d = new Date(dateStr)
  return d.toLocaleDateString("id-ID", {
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  })
}

export default function ReportDetailPage() {
  const params = useParams()
  const router = useRouter()
  const [report, setReport] = useState(null)
  const [loading, setLoading] = useState(true)

  const fetchReport = async () => {
    try {
      setLoading(true)
      const { data, error } = await reportService.getById(params.id)
      if (error) throw error
      setReport(data)
    } catch (err) {
      console.error(err)
      toast.error("Gagal memuat dokumen laporan")
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (params.id) fetchReport()
  }, [params.id])

  const handleStatusChange = async (newStatus) => {
    try {
      const loadingToast = toast.loading("Memperbarui status...")
      const { error } = await reportService.updateStatus(params.id, newStatus)
      if (error) throw error
      toast.dismiss(loadingToast)
      toast.success("Status dokumen berhasil diperbarui")
      fetchReport()
    } catch (err) {
      toast.error("Gagal mengubah status dokumen")
    }
  }

  const handleDelete = async () => {
    if (!confirm("Hapus ulasan laporan aduan ini secara permanen?")) return
    try {
      const loadingToast = toast.loading("Memproses penghapusan...")
      await reportService.delete(params.id)
      toast.dismiss(loadingToast)
      toast.success("Dokumen laporan berhasil ditarik")
      setTimeout(() => router.push("/pelaporan"), 800)
    } catch (err) {
      toast.error("Gagal menghapus dokumen laporan")
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen p-6 md:p-10 flex items-center justify-center font-sans">
        <div className="flex items-center gap-3 text-gray-500">
          <div className="w-5 h-5 border-2 border-gray-300 dark:border-gray-600 border-t-blue-500 rounded-full animate-spin"></div>
          <span className="text-sm font-medium">Memuat detail dokumen...</span>
        </div>
      </div>
    )
  }

  if (!report) {
    return (
      <div className="min-h-screen p-6 md:p-10 flex flex-col items-center justify-center font-sans">
        <div className="p-4 rounded-full bg-gray-100 dark:bg-white/5 mb-4">
            <XCircle className="w-8 h-8 text-gray-400" />
        </div>
        <p className="text-gray-900 dark:text-white font-medium mb-1">Dokumen Tidak Ditemukan</p>
        <p className="text-sm text-gray-500 dark:text-gray-400">Arsip aduan mungkin telah terhapus atau tautan salah.</p>
        <Link href="/pelaporan" className="mt-6 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition">
            Kembali ke Daftar
        </Link>
      </div>
    )
  }

  const statusConf = STATUS_STYLES[report.status] || STATUS_STYLES.pending

  return (
    <div className="min-h-screen p-6 md:p-10 font-sans max-w-4xl mx-auto">
      
      {/* Navigate Back */}
      <Link
        href="/pelaporan"
        className="inline-flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white font-medium transition-colors mb-6"
      >
        <ArrowLeft className="w-4 h-4" />
        Daftar Pelaporan
      </Link>

      <div className="bg-white dark:bg-[#1a1a2e] border border-gray-200 dark:border-white/10 rounded-xl shadow-sm overflow-hidden">
         {/* Document Header */}
         <div className="px-6 md:px-8 py-6 border-b border-gray-200 dark:border-white/10 flex flex-col md:flex-row md:items-end justify-between gap-4 bg-gray-50/50 dark:bg-black/10">
            <div>
                <div className="flex items-center gap-2 mb-3">
                   <span className="px-2.5 py-1 text-[11px] font-semibold bg-gray-200 text-gray-700 dark:bg-white/10 dark:text-gray-300 rounded uppercase tracking-wider">
                       Kategori: {report.category}
                   </span>
                   <span className={`px-2.5 py-1 text-[11px] font-semibold rounded uppercase tracking-wider ${statusConf.bg} ${statusConf.text}`}>
                       {statusConf.label}
                   </span>
                </div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white leading-tight">
                    {report.title}
                </h1>
                <p className="flex items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400 mt-2 font-mono">
                   <Calendar className="w-3.5 h-3.5" />
                   {formatDate(report.created_at)}
                </p>
            </div>

            <button
                onClick={handleDelete}
                className="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 dark:text-red-400 dark:bg-red-500/10 dark:hover:bg-red-500/20 border border-red-200 dark:border-red-500/30 rounded-lg transition-colors"
            >
                <Trash2 className="w-4 h-4" />
                Hapus Dokumen
            </button>
         </div>

         {/* Document Body */}
         <div className="p-6 md:p-8">
            <div className="grid md:grid-cols-3 gap-8">
                
                {/* Left col - Details */}
                <div className="md:col-span-2 space-y-8">
                    
                    {/* Description Paragraphs */}
                    <div className="space-y-3">
                        <h3 className="text-sm font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-white/10 pb-2">Deskripsi Aduan</h3>
                        <div className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap bg-gray-50 dark:bg-white/5 p-4 rounded-lg border border-gray-100 dark:border-white/5">
                            {report.description}
                        </div>
                    </div>

                    {/* Photographic Evidence */}
                    <div className="space-y-3">
                        <h3 className="text-sm font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-white/10 pb-2">Bukti Lampiran Visual</h3>
                        {report.image_url ? (
                            <div className="rounded-xl overflow-hidden border border-gray-200 dark:border-white/10 bg-gray-100 dark:bg-black/20">
                                <img
                                    src={report.image_url}
                                    alt="Bukti Lampiran"
                                    className="w-full max-h-[400px] object-contain"
                                />
                            </div>
                        ) : (
                            <div className="flex flex-col items-center justify-center py-10 px-4 rounded-xl border border-dashed border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-black/10">
                                <CameraOff className="w-8 h-8 text-gray-400 mb-2" />
                                <span className="text-sm text-gray-500 dark:text-gray-400">Tidak ada lampiran media yang dilampirkan pelapor.</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Right col - Metadata Sidebar */}
                <div className="space-y-6">
                    <div className="bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl p-5 space-y-5">
                       
                       <div className="space-y-1">
                           <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider">Informasi Pelapor</span>
                           <p className="text-sm font-medium text-gray-900 dark:text-white">{report.reporter_name}</p>
                       </div>

                       {report.phone && (
                         <div className="space-y-1">
                             <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider flex items-center gap-1"><Phone className="w-3 h-3"/> Kontak Telepon</span>
                             <p className="text-sm font-medium text-gray-900 dark:text-white">{report.phone}</p>
                         </div>
                       )}

                       {report.location && (
                         <div className="space-y-1">
                             <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider flex items-center gap-1"><MapPin className="w-3 h-3"/> Koordinat / Alamat</span>
                             <p className="text-sm font-medium text-gray-900 dark:text-white leading-snug">{report.location}</p>
                         </div>
                       )}
                    </div>

                    <div className="bg-blue-50/50 dark:bg-blue-900/10 border border-blue-100 dark:border-blue-800/30 rounded-xl p-5 space-y-3">
                        <span className="text-[10px] uppercase font-bold text-blue-600 dark:text-blue-400 tracking-wider block mb-2">Manajemen Tiket</span>
                        
                        <div className="flex flex-col gap-2">
                          {STATUS_OPTIONS.map((opt) => {
                            const Icon = opt.icon
                            const isSelected = report.status === opt.value
                            return (
                                <button
                                    key={opt.value}
                                    onClick={() => handleStatusChange(opt.value)}
                                    disabled={isSelected}
                                    className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-semibold text-left transition-colors border
                                        ${isSelected 
                                            ? "bg-blue-600 border-blue-600 text-white shadow-sm" 
                                            : "bg-white border-gray-200 text-gray-600 hover:bg-gray-50 dark:bg-transparent dark:border-gray-700 dark:text-gray-400 dark:hover:bg-white/5"}
                                    `}
                                >
                                    <Icon className={`w-3.5 h-3.5 ${isSelected ? 'text-white' : 'text-gray-400'}`} />
                                    {opt.label}
                                </button>
                            )
                          })}
                        </div>
                    </div>
                </div>

            </div>
         </div>

      </div>
    </div>
  )
}
