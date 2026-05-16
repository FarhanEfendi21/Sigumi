import { supabase } from "@/lib/supabase/client"

export const uploadImage = async (file) => {
  const fileName = `${Date.now()}-${file.name}`

  const { error } = await supabase.storage
    .from("images")
    .upload(fileName, file)

  if (error) throw error

  const { data } = supabase.storage
    .from("images")
    .getPublicUrl(fileName)

  return data.publicUrl
}