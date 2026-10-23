-- ─────────────────────────────────────────────
-- Presupuesto en pareja · base de datos Supabase
-- Pégalo completo en: Supabase → SQL Editor → New query → Run
-- ANTES de correrlo, cambia los dos correos de abajo.
-- Se puede volver a correr sin perder datos.
-- ─────────────────────────────────────────────

-- Rubros (comida, ocio, viajes…) con su tope mensual
create table if not exists public.categorias (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  nombre      text not null,
  tope        numeric(12,2) not null default 0 check (tope >= 0),
  orden       int not null default 0
);

-- Movimientos: ingresos, gastos y traspasos entre fondos
create table if not exists public.movimientos (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  fecha       date not null default current_date,
  persona     text not null,
  tipo        text not null check (tipo in ('ingreso', 'gasto', 'traspaso')),
  medio       text not null,           -- fondo: banco / efectivo / ahorro (en traspaso = destino)
  monto       numeric(12,2) not null check (monto > 0),
  concepto    text not null default '',
  creado_por  uuid default auth.uid()
);
alter table public.movimientos add column if not exists origen text;   -- solo en traspasos
alter table public.movimientos add column if not exists categoria uuid references public.categorias(id) on delete set null;

alter table public.movimientos drop constraint if exists movimientos_medio_check;
alter table public.movimientos add constraint movimientos_medio_check check (medio in ('banco', 'efectivo', 'ahorro'));
alter table public.movimientos drop constraint if exists movimientos_origen_check;
alter table public.movimientos add constraint movimientos_origen_check check (origen is null or origen in ('banco', 'efectivo', 'ahorro'));

create index if not exists movimientos_fecha_idx on public.movimientos (fecha desc);

-- Rubros iniciales (solo si la tabla está vacía)
insert into public.categorias (nombre, orden)
select v.nombre, v.orden from (values
  ('Vivienda', 1), ('Comida', 2), ('Transporte', 3), ('Servicios', 4),
  ('Ocio', 5), ('Viajes', 6), ('Salud', 7), ('Otros', 8)
) as v(nombre, orden)
where not exists (select 1 from public.categorias);

-- Solo ustedes dos pueden leer y escribir.
create or replace function public.es_pareja()
returns boolean language sql stable as $$
  select coalesce(auth.jwt() ->> 'email', '') in (
    'mralealvarez@gmail.com',
    'luisafernandavelezcruz@gmail.com'
  );
$$;

do $$
declare t text;
begin
  foreach t in array array['movimientos', 'categorias'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists pareja_select on public.%I', t);
    execute format('drop policy if exists pareja_insert on public.%I', t);
    execute format('drop policy if exists pareja_update on public.%I', t);
    execute format('drop policy if exists pareja_delete on public.%I', t);
    execute format('create policy pareja_select on public.%I for select to authenticated using (public.es_pareja())', t);
    execute format('create policy pareja_insert on public.%I for insert to authenticated with check (public.es_pareja())', t);
    execute format('create policy pareja_update on public.%I for update to authenticated using (public.es_pareja()) with check (public.es_pareja())', t);
    execute format('create policy pareja_delete on public.%I for delete to authenticated using (public.es_pareja())', t);
    -- Tiempo real entre los dos teléfonos
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;
