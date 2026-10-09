import type { LinkProps } from '@tanstack/react-router'
import {
  Banknote,
  ChartColumn,
  ClipboardList,
  LayoutDashboard,
  MapPinned,
  Megaphone,
  Store,
  UtensilsCrossed,
  Users,
  type LucideIcon,
} from 'lucide-react'

export interface NavItem {
  label: string
  icon: LucideIcon
  /** Sin `to`: módulo planificado, se muestra como "Pronto". */
  to?: LinkProps['to']
}

export interface NavPortal {
  label: string
  items: NavItem[]
}

export const navigation = {
  ADMIN: {
    label: 'Administración',
    items: [
      { label: 'Inicio', icon: LayoutDashboard, to: '/admin' },
      { label: 'Pedidos', icon: ClipboardList, to: '/admin/orders' },
      { label: 'Socios', icon: Users, to: '/admin/partners' },
      { label: 'Catálogo', icon: UtensilsCrossed, to: '/admin/catalog' },
      { label: 'Marketing', icon: Megaphone, to: '/admin/marketing' },
      { label: 'Ciudades', icon: MapPinned, to: '/admin/cities' },
      { label: 'Caja', icon: Banknote, to: '/admin/cash' },
    ],
  },
  MERCHANT: {
    label: 'Portal Socios',
    items: [
      { label: 'Inicio', icon: LayoutDashboard, to: '/partner' },
      { label: 'Mi tienda', icon: Store, to: '/partner/store' },
      { label: 'Menú', icon: UtensilsCrossed, to: '/partner/menu' },
      { label: 'Reportes', icon: ChartColumn, to: '/partner/reports' },
      { label: 'Rendición', icon: Banknote, to: '/partner/settlement' },
    ],
  },
} satisfies Record<'ADMIN' | 'MERCHANT', NavPortal>
