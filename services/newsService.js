import { supabase } from "@/lib/supabase/client"
import { getAdminLocation } from "@/lib/utils/auth"

export const newsService = {
  async getAll() {
    let query = supabase.from("news").select("*").order("created_at", { ascending: false })
    
    const adminLocation = getAdminLocation()
    if (adminLocation) {
      query = query.eq("lokasi", adminLocation)
    }

    return await query
  },

  async create(data) {
    const adminLocation = getAdminLocation()
    
    const payload = {
      ...data,
      ...(adminLocation && { lokasi: adminLocation }),
      updated_at: new Date().toISOString(),
    }

    const result = await supabase.from("news").insert([payload])

    if (result.error?.message?.includes("updated_at")) {
      const fallbackPayload = {
        ...data,
        ...(adminLocation && { lokasi: adminLocation }),
      }
      return await supabase.from("news").insert([fallbackPayload])
    }

    return result
  },

  async getById(id) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("news").select("*").eq("id", id)
    if (adminLocation) query = query.eq("lokasi", adminLocation)
    return await query.single()
  },

  async delete(id) {
    const adminLocation = getAdminLocation()
    let query = supabase.from("news").delete().eq("id", id)
    if (adminLocation) query = query.eq("lokasi", adminLocation)
    return await query
  },

  async update(id, data) {
    const adminLocation = getAdminLocation()
    const payload = {
      ...data,
      updated_at: new Date().toISOString(),
    }

    let query = supabase.from("news").update(payload).eq("id", id)
    if (adminLocation) query = query.eq("lokasi", adminLocation)
    
    const result = await query

    if (result.error?.message?.includes("updated_at")) {
      let fallbackQuery = supabase.from("news").update(data).eq("id", id)
      if (adminLocation) fallbackQuery = fallbackQuery.eq("lokasi", adminLocation)
      return await fallbackQuery
    }

    return result
  },
}