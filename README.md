# Chaski

> Nombre provisional. App de delivery multi-negocio (restaurantes, tiendas, farmacias) pensada para una ciudad pequeña y preparada para escalar a varias ciudades.

## Monorepo

```
chaski/
├── backend/     # API NestJS + Prisma + PostgreSQL
├── mobile/      # App Flutter para el CUSTOMER
├── docs/        # Arquitectura, decisiones y API
└── docker-compose.yml   # Postgres 16 para desarrollo (puerto 5433)
```

## Documentación

- [Arquitectura y diseño inicial](docs/ARQUITECTURA.md) (v0.5)
- [Backend: arranque y endpoints](backend/README.md)
- [Qué falta para el MVP](docs/PENDIENTES.md)

## Estado

- **mobile**: flujo completo del cliente, con datos de demo (`env/fake.json`) o contra la API (`env/dev.json`).
- **backend**: Fase 1 lista (auth por OTP, catálogo, búsqueda, discovery, seed de Espinar). Siguiente: cupones y pedidos.
