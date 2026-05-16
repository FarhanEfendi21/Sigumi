"use client"

import { useState, useMemo, useCallback, useEffect, useRef } from "react"
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet"
import L from "leaflet"
import "leaflet/dist/leaflet.css"
import { getDistance } from "geolib"
import { Search, Loader2, MapPin, X } from "lucide-react"

// Fix for default marker icon issue in Leaflet + Next.js
const markerIcon = new L.Icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
})

const volcanoCoords = {
  "a1b2c3d4-e5f6-7890-abcd-111111111111": { lat: -7.5407, lng: 110.4463 }, // Merapi
  "a1b2c3d4-e5f6-7890-abcd-222222222222": { lat: -8.342, lng: 115.508 },  // Agung
  "a1b2c3d4-e5f6-7890-abcd-333333333333": { lat: -8.411, lng: 116.457 },  // Rinjani
}

function MapEvents({ onLocationSelect }) {
  useMapEvents({
    click(e) {
      onLocationSelect(e.latlng)
    },
  })
  return null
}

function RecenterMap({ position }) {
  const map = useMapEvents({})
  useEffect(() => {
    if (position) {
      map.setView([position.lat, position.lng], map.getZoom())
    }
  }, [position, map])
  return null
}

// Search bar component with Nominatim geocoding
function LocationSearch({ onSelect }) {
  const [query, setQuery] = useState("")
  const [results, setResults] = useState([])
  const [searching, setSearching] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const debounceRef = useRef(null)
  const containerRef = useRef(null)

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setShowResults(false)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  const searchLocation = useCallback(async (searchQuery) => {
    if (!searchQuery || searchQuery.trim().length < 3) {
      setResults([])
      return
    }

    setSearching(true)
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&countrycodes=id&limit=5&accept-language=id`
      )
      const data = await res.json()
      setResults(data || [])
      setShowResults(true)
    } catch (err) {
      console.error("Search error:", err)
      setResults([])
    } finally {
      setSearching(false)
    }
  }, [])

  const handleInputChange = (e) => {
    const value = e.target.value
    setQuery(value)

    // Debounce search (500ms)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      searchLocation(value)
    }, 500)
  }

  const handleSelect = (item) => {
    const latlng = { lat: parseFloat(item.lat), lng: parseFloat(item.lon) }
    onSelect(latlng)
    setQuery(item.display_name)
    setShowResults(false)
    setResults([])
  }

  const handleClear = () => {
    setQuery("")
    setResults([])
    setShowResults(false)
  }

  const handleKeyDown = (e) => {
    if (e.key === "Enter") {
      e.preventDefault()
      if (debounceRef.current) clearTimeout(debounceRef.current)
      searchLocation(query)
    }
    if (e.key === "Escape") {
      setShowResults(false)
    }
  }

  return (
    <div ref={containerRef} className="absolute top-4 right-4 left-14 md:left-auto md:w-80 z-[1000]">
      {/* Search Input */}
      <div className="relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          {searching ? (
            <Loader2 className="w-4 h-4 text-blue-500 animate-spin" />
          ) : (
            <Search className="w-4 h-4 text-gray-400" />
          )}
        </div>
        <input
          type="text"
          value={query}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          onFocus={() => results.length > 0 && setShowResults(true)}
          placeholder="Cari lokasi... (contoh: Stadion Maguwoharjo)"
          className="w-full pl-10 pr-9 py-2.5 rounded-lg bg-white dark:bg-[#1a1a2e] border border-gray-300 dark:border-white/20 text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 outline-none shadow-lg backdrop-blur-sm transition-all"
        />
        {query && (
          <button
            type="button"
            onClick={handleClear}
            className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Results Dropdown */}
      {showResults && results.length > 0 && (
        <div className="mt-1.5 bg-white dark:bg-[#1a1a2e] border border-gray-200 dark:border-white/10 rounded-lg shadow-xl overflow-hidden max-h-[220px] overflow-y-auto">
          {results.map((item, idx) => (
            <button
              key={item.place_id || idx}
              type="button"
              onClick={() => handleSelect(item)}
              className="w-full text-left px-3 py-2.5 hover:bg-blue-50 dark:hover:bg-blue-500/10 transition-colors flex items-start gap-2.5 border-b border-gray-100 dark:border-white/5 last:border-0"
            >
              <MapPin className="w-4 h-4 text-blue-500 mt-0.5 shrink-0" />
              <div className="min-w-0 flex-1">
                <p className="text-sm text-gray-900 dark:text-white font-medium truncate">
                  {item.display_name?.split(",")[0]}
                </p>
                <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
                  {item.display_name}
                </p>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* No Results */}
      {showResults && results.length === 0 && !searching && query.length >= 3 && (
        <div className="mt-1.5 bg-white dark:bg-[#1a1a2e] border border-gray-200 dark:border-white/10 rounded-lg shadow-xl px-4 py-3">
          <p className="text-sm text-gray-500 dark:text-gray-400 text-center">Lokasi tidak ditemukan</p>
        </div>
      )}
    </div>
  )
}

export default function MapPicker({ selectedVolcanoId, onLocationChange, initialPosition }) {
  const referenceCoords = useMemo(() => 
    initialPosition || volcanoCoords[selectedVolcanoId] || { lat: -7.7956, lng: 110.3695 }
  , [initialPosition, selectedVolcanoId])
  
  const [position, setPosition] = useState(referenceCoords)
  const isFirstRender = useRef(true)

  // Update position when volcano changes, but only if not first render with initialPosition
  useEffect(() => {
    if (isFirstRender.current && initialPosition) {
      isFirstRender.current = false
      return
    }

    if (volcanoCoords[selectedVolcanoId]) {
      const newPos = volcanoCoords[selectedVolcanoId]
      setPosition(newPos)
      handleLocationUpdate(newPos)
    }
    isFirstRender.current = false
  }, [selectedVolcanoId])

  const handleLocationUpdate = useCallback(
    async (latlng) => {
      setPosition(latlng)
      
      // Calculate distance in KM
      let distanceKm = 0
      if (volcanoCoords[selectedVolcanoId]) {
        const distMeters = getDistance(
          { latitude: latlng.lat, longitude: latlng.lng },
          { latitude: volcanoCoords[selectedVolcanoId].lat, longitude: volcanoCoords[selectedVolcanoId].lng }
        )
        distanceKm = parseFloat((distMeters / 1000).toFixed(2))
      }

      // Reverse Geocoding (Nominatim)
      let address = ""
      try {
        const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latlng.lat}&lon=${latlng.lng}&zoom=18&addressdetails=1&accept-language=id`)
        const data = await res.json()
        address = data.display_name || ""
      } catch (err) {
        console.error("Geocoding error:", err)
      }

      onLocationChange({
        lat: latlng.lat,
        lng: latlng.lng,
        distanceKm,
        address
      })
    },
    [selectedVolcanoId, onLocationChange]
  )

  const eventHandlers = useMemo(
    () => ({
      dragend(e) {
        const marker = e.target
        if (marker != null) {
          handleLocationUpdate(marker.getLatLng())
        }
      },
    }),
    [handleLocationUpdate]
  )

  return (
    <div className="h-[400px] w-full rounded-xl overflow-hidden border border-gray-200 dark:border-white/10 relative z-10">
      <MapContainer
        center={[position.lat, position.lng]}
        zoom={13}
        scrollWheelZoom={false}
        className="h-full w-full"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <Marker
          draggable={true}
          eventHandlers={eventHandlers}
          position={[position.lat, position.lng]}
          icon={markerIcon}
        />
        <MapEvents onLocationSelect={handleLocationUpdate} />
        <RecenterMap position={position} />
      </MapContainer>

      {/* Search Bar Overlay */}
      <LocationSearch onSelect={handleLocationUpdate} />

      <div className="absolute bottom-4 left-4 z-[1000] bg-white/90 dark:bg-[#1a1a2e]/90 p-2 rounded shadow-sm text-[10px] text-gray-500 font-medium border border-gray-200 dark:border-white/10 uppercase tracking-wider">
        Cari lokasi, klik peta, atau geser pin
      </div>
    </div>
  )
}
