defmodule ACOrigins do
  # https://www.reddit.com/r/assassinscreed/comments/7dwpqu/assassins_creed_origins_weapons_list/
  # https://imageshack.com/a/3cTl/1
  
  def run do
    load_json() 
      |> add_slug_to_map() 
      |> add_image_folder_to_map() 
      |> download_images()
  end

  def transform_json do
    load_json() 
      |> add_slug_to_map() 
      |> add_image_folder_to_map() 
      |> save_json() 
    
  end

  def load_json do
    {:ok, content} = File.read("weapon-list.json")
    {:ok, weapon_list} = Poison.decode(content)

    weapon_list
  end

  def save_json(weapon_list) when is_list(weapon_list) do
    {:ok, json} = Poison.encode weapon_list, pretty: true
    File.write("weapon-list-ready.json", json)
  end

  def add_slug_to_map(weapon_list) when is_list(weapon_list) do
    Enum.map(weapon_list, fn %{"name" => name} = weapon ->
      Map.put(weapon, "slug", Slugger.slugify_downcase name)
    end)
  end

  def add_image_folder_to_map(weapon_list) when is_list(weapon_list) do
    Enum.map(weapon_list, fn %{"slug" => slug, "type" => type, "subtype" => subtype} = weapon ->
      case {slug, type, subtype} do
         {s, t, ""} -> modify_weapon_map(weapon, "images/#{t}", s)
         {s, t, st} -> modify_weapon_map(weapon, "images/#{t}/#{st}", s)
      end
    end)
  end

  defp modify_weapon_map(%{"slug" => slug, "image" => image_url} = weapon, folder, slug) do
    image_info = %{
      "folder" => folder,
      "filepath" => "#{folder}/#{slug}.png",
      "url" => image_url
    }

    Map.put(weapon, "image", image_info)
  end

  def download_images(weapon_list) when is_list(weapon_list) do
    Enum.map(weapon_list, fn w -> get_single_image(w) end)
  end

  def get_single_image(%{"image" => image_url, "image_folder" => folder, "image_filename" => filename}) do
    IO.puts "...Downloading [#{filename}] from [#{image_url}]"

    %HTTPoison.Response{body: body} = HTTPoison.get!(image_url)
    if not File.exists?(folder) do
      File.mkdir_p!(folder)
    end
    File.write!(filename, body)
  end

end
