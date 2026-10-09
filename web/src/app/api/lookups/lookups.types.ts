// Contratos compartidos por Socios y Catálogo, contrastados con admin/*.
export interface CityOption {
  id: string
  name: string
  currency: string
  centerLat: number
  centerLng: number
}

export interface StoreSummary {
  id: string
  cityId: string
  ownerId: string
  name: string
  isActive: boolean
  isAcceptingOrders: boolean
  productCount: number
}

export interface PartnerAccount {
  id: string
  phone: string
  firstName: string
  lastName: string
  isActive: boolean
  roles: string[]
  stores: { id: string; name: string; isAcceptingOrders: boolean }[]
  courier: {
    cityId: string
    vehicleType: 'MOTO' | 'BICI' | 'AUTO'
    vehicleLabel: string
    plate: string | null
    status: string
  } | null
}
