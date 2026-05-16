import { supabase } from "@/lib/supabase/client"

export const userService = {
  async getAll() {
    return await supabase
      .from("profiles")
      .select("*")
      .order("created_at", { ascending: false })
  },

  async delete(id) {
    return await supabase.from("profiles").delete().eq("id", id)
  },
}
