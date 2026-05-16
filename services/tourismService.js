import { supabase } from "@/lib/supabase/client"
import { getAdminLocation } from "@/lib/utils/auth"

export const tourismService = {
  async getAll() {
    let query = supabase.from("tourism_destinations").select("*").order("created_at", { ascending: false })
    
    const adminLocation = getAdminLocation()
    if (adminLocation) {
      query = query.eq("region", adminLocation)
    }

    return await query
  },

  async create(data) {
    const adminLocation = getAdminLocation()

    const payload = {
      ...data,
      ...(adminLocation && { region: adminLocation }),
      created_at: new Date().toISOString(),
    }
    const result = await supabase.from("tourism_destinations").insert([payload])
    
    if (result.error?.message?.includes("created_at")) {
      const fallbackPayload = {
        ...data,
        ...(adminLocation && { region: adminLocation }),
      }
      return await supabase.from("tourism_destinations").insert([fallbackPayload])
    }
    return result
  },

  async delete(id) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("tourism_destinations").delete().eq("id", id)
    if (adminLocation) query = query.eq("region", adminLocation)
    return await query
  },

  async update(id, data) {
    const adminLocation = getAdminLocation()
    const { id: _id, created_at, ...payload } = data
    
    let query = supabase.from("tourism_destinations").update(payload).eq("id", id)
    if (adminLocation) query = query.eq("region", adminLocation)
    return await query
  },

  async getById(id) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("tourism_destinations").select("*").eq("id", id)
    if (adminLocation) query = query.eq("region", adminLocation)
    return await query.single()
  }
}
