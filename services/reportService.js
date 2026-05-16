import { supabase } from "@/lib/supabase/client"
import { getAdminLocation } from "@/lib/utils/auth"

export const reportService = {
  async getAll() {
    let query = supabase.from("reports").select("*").order("created_at", { ascending: false })
    
    const adminLocation = getAdminLocation()
    if (adminLocation) {
      query = query.eq("lokasi", adminLocation)
    }

    return await query
  },

  async getById(id) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("reports").select("*").eq("id", id)
    if (adminLocation) query = query.eq("lokasi", adminLocation)
    return await query.single()
  },

  async create(data) {
    const payload = {
      ...data,
      updated_at: new Date().toISOString(),
    }
    return await supabase.from("reports").insert([payload])
  },

  async updateStatus(id, status) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("reports").update({ status, updated_at: new Date().toISOString() }).eq("id", id)
    if (adminLocation) query = query.eq("lokasi", adminLocation)
    return await query
  },

  async delete(id) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("reports").delete().eq("id", id)
    if (adminLocation) query = query.eq("lokasi", adminLocation)
    return await query
  },
}
