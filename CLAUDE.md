# Apamuy

La marca es **Apamuy** ("tráelo" en quechua); la app de negocios y repartidores es **Apamuy Socios**. El nombre interno `chaski` solo queda en la carpeta raíz del proyecto.

Monorepo de una app de delivery para Espinar (Cusco): `backend/` (NestJS + Prisma), `mobile/` (Flutter, app del cliente), `web/` (React, panel Admin y Portal Socios: ver `docs/PANEL_WEB.md`), `docs/`.

- Diseño y decisiones: `docs/ARQUITECTURA.md`. Qué falta: `docs/PENDIENTES.md`.
- Textos para el usuario, mensajes de error y docs en **español**. Identificadores y código en inglés.
- Reglas de cada parte en `backend/CLAUDE.md`, `mobile/CLAUDE.md` y `web/CLAUDE.md`.

## Skills instaladas y precedencia

Hay skills genéricas de NestJS (`.claude/skills/nestjs-*`) y el plugin oficial `dart-flutter`. Úsalas para buenas prácticas, pero **las convenciones de este repo mandan**: si una skill sugiere algo que contradice `docs/ARQUITECTURA.md` o los `CLAUDE.md`, se sigue el repo. Por ejemplo, sus ejemplos usan TypeORM, Passport, mockito o el paquete `http`; aquí no.
