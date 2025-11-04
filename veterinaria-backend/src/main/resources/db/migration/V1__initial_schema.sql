-- ============================================
-- MIGRACIÓN V1: ESQUEMA INICIAL COMPLETO
-- Sistema de Gestión Clínica Veterinaria
-- ============================================
-- Fecha: 2024-11-03
-- Descripción: Crea todas las tablas del sistema con constraints e índices
-- ============================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- Para generar UUIDs

-- ============================================
-- SECCIÓN 1: GESTIÓN DE USUARIOS
-- ============================================
-- ============================================
-- MÓDULO 1: GESTIÓN DE USUARIOS
-- ============================================

-- Tabla: roles
CREATE TABLE roles (
                       id_rol BIGSERIAL PRIMARY KEY,
                       nombre_rol VARCHAR(50) NOT NULL UNIQUE,
                       descripcion VARCHAR(255),
                       fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                       fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE roles IS 'Roles del sistema (Admin, Veterinario, Cliente, Secretario)';

-- Tabla: permisos
CREATE TABLE permisos (
                          id_permiso BIGSERIAL PRIMARY KEY,
                          nombre VARCHAR(100) NOT NULL UNIQUE,
                          descripcion VARCHAR(255),
                          recurso VARCHAR(100) NOT NULL,
                          accion VARCHAR(50) NOT NULL,
                          fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE permisos IS 'Permisos granulares del sistema';

-- Tabla: rol_permiso (intermedia N:M)
CREATE TABLE rol_permiso (
                             rol_id BIGINT NOT NULL,
                             permiso_id BIGINT NOT NULL,
                             fecha_asignacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                             PRIMARY KEY (rol_id, permiso_id),
                             CONSTRAINT fk_rol_permiso_rol FOREIGN KEY (rol_id)
                                 REFERENCES roles(id_rol) ON DELETE CASCADE,
                             CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (permiso_id)
                                 REFERENCES permisos(id_permiso) ON DELETE CASCADE
);

COMMENT ON TABLE rol_permiso IS 'Relación muchos a muchos entre roles y permisos';

-- Tabla: usuarios (base para herencia)
CREATE TABLE usuarios (
                          id_usuario BIGSERIAL PRIMARY KEY,
                          username VARCHAR(60) NOT NULL UNIQUE,
                          password_hash VARCHAR(255) NOT NULL,
                          activo BOOLEAN DEFAULT TRUE,
                          ultimo_acceso TIMESTAMP WITH TIME ZONE,
                          rol_id BIGINT NOT NULL,
                          tipo_usuario VARCHAR(20) NOT NULL, -- 'CLIENTE', 'VETERINARIO', 'SECRETARIO'

    -- Campos de Persona (común a todos)
                          nombre VARCHAR(100) NOT NULL,
                          apellido VARCHAR(100) NOT NULL,
                          correo VARCHAR(150) NOT NULL UNIQUE,
                          telefono VARCHAR(30),
                          direccion VARCHAR(255),

    -- Auditoría
                          fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                          fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                          CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id)
                              REFERENCES roles(id_rol),
                          CONSTRAINT chk_tipo_usuario CHECK (tipo_usuario IN ('CLIENTE', 'VETERINARIO', 'SECRETARIO'))
);

COMMENT ON TABLE usuarios IS 'Tabla base de usuarios con herencia por tipo';
COMMENT ON COLUMN usuarios.tipo_usuario IS 'Discriminador para herencia: CLIENTE, VETERINARIO, SECRETARIO';

-- Tabla: clientes (especialización de usuario)
CREATE TABLE clientes (
                          id_cliente BIGSERIAL PRIMARY KEY,
                          usuario_id BIGINT NOT NULL UNIQUE,
                          fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                          documento_identidad VARCHAR(50) UNIQUE,
                          tipo_documento VARCHAR(20),

                          CONSTRAINT fk_cliente_usuario FOREIGN KEY (usuario_id)
                              REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

COMMENT ON TABLE clientes IS 'Información específica de clientes (propietarios de mascotas)';

-- Tabla: veterinarios (especialización de usuario)
CREATE TABLE veterinarios (
                              id_veterinario BIGSERIAL PRIMARY KEY,
                              usuario_id BIGINT NOT NULL UNIQUE,
                              licencia_profesional VARCHAR(100) UNIQUE,
                              especialidad VARCHAR(100),
                              disponibilidad JSONB, -- {lunes: ["09:00-13:00", "14:00-18:00"], ...}

                              CONSTRAINT fk_veterinario_usuario FOREIGN KEY (usuario_id)
                                  REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

COMMENT ON TABLE veterinarios IS 'Información específica de veterinarios';
COMMENT ON COLUMN veterinarios.disponibilidad IS 'Horarios de disponibilidad en formato JSON';

-- Tabla: secretarios (especialización de usuario)
CREATE TABLE secretarios (
                             id_secretario BIGSERIAL PRIMARY KEY,
                             usuario_id BIGINT NOT NULL UNIQUE,
                             extension VARCHAR(20),
                             area_asignada VARCHAR(100),

                             CONSTRAINT fk_secretario_usuario FOREIGN KEY (usuario_id)
                                 REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

COMMENT ON TABLE secretarios IS 'Información específica de secretarios/recepcionistas';

-- Tabla: historial_acciones (auditoría)
CREATE TABLE historial_acciones (
                                    id_accion BIGSERIAL PRIMARY KEY,
                                    usuario_id BIGINT NOT NULL,
                                    fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    descripcion TEXT NOT NULL,
                                    metadata JSONB,
                                    ip_address VARCHAR(45),

                                    CONSTRAINT fk_historial_usuario FOREIGN KEY (usuario_id)
                                        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

COMMENT ON TABLE historial_acciones IS 'Log de auditoría de acciones de usuarios';

-- Índices para Gestión de Usuarios
CREATE INDEX idx_usuarios_correo ON usuarios(correo);
CREATE INDEX idx_usuarios_username ON usuarios(username);
CREATE INDEX idx_usuarios_rol ON usuarios(rol_id);
CREATE INDEX idx_usuarios_tipo ON usuarios(tipo_usuario);
CREATE INDEX idx_historial_usuario ON historial_acciones(usuario_id);
CREATE INDEX idx_historial_fecha ON historial_acciones(fecha_hora DESC);

-- ============================================
-- SECCIÓN 2: GESTIÓN DE PACIENTES
-- ============================================
-- ============================================
-- MÓDULO 3: GESTIÓN DE PACIENTES
-- ============================================

-- Tabla: pacientes
CREATE TABLE pacientes (
                           id_paciente BIGSERIAL PRIMARY KEY,
                           nombre VARCHAR(100) NOT NULL,
                           especie VARCHAR(30) NOT NULL,
                           raza VARCHAR(80),
                           fecha_nacimiento DATE NOT NULL,
                           sexo VARCHAR(10),
                           peso_kg NUMERIC(5,2),
                           estado_salud VARCHAR(100),
                           cliente_id BIGINT NOT NULL,
                           identificador_externo UUID DEFAULT uuid_generate_v4() UNIQUE,
                           activo BOOLEAN DEFAULT TRUE,

    -- Auditoría
                           fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                           fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                           CONSTRAINT fk_paciente_cliente FOREIGN KEY (cliente_id)
                               REFERENCES clientes(id_cliente),
                           CONSTRAINT chk_especie CHECK (especie IN ('perro', 'gato')),
                           CONSTRAINT chk_peso CHECK (peso_kg > 0),
                           CONSTRAINT chk_fecha_nacimiento CHECK (fecha_nacimiento <= CURRENT_DATE)
);

COMMENT ON TABLE pacientes IS 'Mascotas registradas en el sistema';
COMMENT ON COLUMN pacientes.identificador_externo IS 'UUID para integración con sistemas externos';

-- Tabla: historias_clinicas (1:1 con paciente)
CREATE TABLE historias_clinicas (
                                    id_historia BIGSERIAL PRIMARY KEY,
                                    paciente_id BIGINT NOT NULL UNIQUE,
                                    fecha_apertura TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    resumen TEXT,
                                    metadatos JSONB,

                                    CONSTRAINT fk_historia_paciente FOREIGN KEY (paciente_id)
                                        REFERENCES pacientes(id_paciente) ON DELETE CASCADE
);

COMMENT ON TABLE historias_clinicas IS 'Historia clínica de cada paciente (relación 1:1)';

-- Tabla: registros_medicos
CREATE TABLE registros_medicos (
                                   id_registro BIGSERIAL PRIMARY KEY,
                                   historia_id BIGINT NOT NULL,
                                   fecha TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                   motivo TEXT NOT NULL,
                                   diagnostico TEXT,
                                   signos_vitales JSONB, -- {temperatura: 38.5, frecuencia_cardiaca: 120, ...}
                                   tratamiento TEXT,
                                   veterinario_id BIGINT NOT NULL,
                                   insumos_usados JSONB, -- [{producto_id: 1, cantidad: 2}, ...]
                                   archivos_adjuntos JSONB, -- [{url: "...", tipo: "imagen"}, ...]
                                   observaciones TEXT,

                                   CONSTRAINT fk_registro_historia FOREIGN KEY (historia_id)
                                       REFERENCES historias_clinicas(id_historia) ON DELETE CASCADE,
                                   CONSTRAINT fk_registro_veterinario FOREIGN KEY (veterinario_id)
                                       REFERENCES veterinarios(id_veterinario)
);

COMMENT ON TABLE registros_medicos IS 'Registros de consultas y procedimientos médicos';

-- Tabla: vacunaciones
CREATE TABLE vacunaciones (
                              id_vacunacion BIGSERIAL PRIMARY KEY,
                              paciente_id BIGINT NOT NULL,
                              tipo_vacuna VARCHAR(100) NOT NULL,
                              fecha_aplicacion DATE NOT NULL,
                              proxima_dosis DATE,
                              veterinario_id BIGINT NOT NULL,
                              lote_vacuna VARCHAR(100),
                              observaciones TEXT,

                              CONSTRAINT fk_vacunacion_paciente FOREIGN KEY (paciente_id)
                                  REFERENCES pacientes(id_paciente) ON DELETE CASCADE,
                              CONSTRAINT fk_vacunacion_veterinario FOREIGN KEY (veterinario_id)
                                  REFERENCES veterinarios(id_veterinario)
);

COMMENT ON TABLE vacunaciones IS 'Registro de vacunas aplicadas';

-- Tabla: desparasitaciones
CREATE TABLE desparasitaciones (
                                   id_desparasitacion BIGSERIAL PRIMARY KEY,
                                   paciente_id BIGINT NOT NULL,
                                   producto_usado VARCHAR(150) NOT NULL,
                                   fecha_aplicacion DATE NOT NULL,
                                   proxima_aplicacion DATE,
                                   veterinario_id BIGINT NOT NULL,
                                   peso_momento NUMERIC(5,2),
                                   dosis VARCHAR(50),

                                   CONSTRAINT fk_desparasitacion_paciente FOREIGN KEY (paciente_id)
                                       REFERENCES pacientes(id_paciente) ON DELETE CASCADE,
                                   CONSTRAINT fk_desparasitacion_veterinario FOREIGN KEY (veterinario_id)
                                       REFERENCES veterinarios(id_veterinario)
);

COMMENT ON TABLE desparasitaciones IS 'Registro de desparasitaciones';

-- Índices para Gestión de Pacientes
CREATE INDEX idx_pacientes_cliente ON pacientes(cliente_id);
CREATE INDEX idx_pacientes_especie ON pacientes(especie);
CREATE INDEX idx_pacientes_activo ON pacientes(activo);
CREATE INDEX idx_pacientes_identificador ON pacientes(identificador_externo);
CREATE INDEX idx_historias_paciente ON historias_clinicas(paciente_id);
CREATE INDEX idx_registros_historia ON registros_medicos(historia_id);
CREATE INDEX idx_registros_fecha ON registros_medicos(fecha DESC);
CREATE INDEX idx_vacunaciones_paciente ON vacunaciones(paciente_id);
CREATE INDEX idx_vacunaciones_proxima ON vacunaciones(proxima_dosis);


-- ============================================
-- SECCIÓN 3: GESTIÓN DE INVENTARIO
-- ============================================
-- ============================================
-- MÓDULO 2: GESTIÓN DE INVENTARIO
-- ============================================

-- Tabla: proveedores
CREATE TABLE proveedores (
                             id_proveedor BIGSERIAL PRIMARY KEY,
                             nombre VARCHAR(150) NOT NULL,
                             contacto VARCHAR(100),
                             telefono VARCHAR(30),
                             direccion VARCHAR(255),
                             correo VARCHAR(150),
                             activo BOOLEAN DEFAULT TRUE,
                             fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                             fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE proveedores IS 'Proveedores de insumos y productos';

-- Tabla: productos
CREATE TABLE productos (
                           id_producto BIGSERIAL PRIMARY KEY,
                           sku VARCHAR(60) NOT NULL UNIQUE,
                           nombre VARCHAR(150) NOT NULL,
                           descripcion TEXT,
                           tipo VARCHAR(50) NOT NULL, -- 'medicamento', 'insumo', 'alimento', 'accesorio'
                           stock INTEGER NOT NULL DEFAULT 0,
                           precio_unitario NUMERIC(12,2) NOT NULL,
                           um VARCHAR(20) NOT NULL, -- unidad de medida: 'unidad', 'ml', 'gr', 'kg'
                           metadatos JSONB,
                           activo BOOLEAN DEFAULT TRUE,
                           fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                           fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                           CONSTRAINT chk_stock CHECK (stock >= 0),
                           CONSTRAINT chk_precio CHECK (precio_unitario >= 0)
);

COMMENT ON TABLE productos IS 'Catálogo de productos e insumos';
COMMENT ON COLUMN productos.sku IS 'Código único del producto (formato: PRD-XXXX)';

-- Tabla: movimientos_inventario
CREATE TABLE movimientos_inventario (
                                        id_movimiento BIGSERIAL PRIMARY KEY,
                                        producto_id BIGINT NOT NULL,
                                        tipo_movimiento VARCHAR(20) NOT NULL, -- 'IN', 'OUT', 'AJUSTE', 'MERMA'
                                        cantidad INTEGER NOT NULL,
                                        fecha TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                        proveedor_id BIGINT, -- NULL para salidas internas
                                        referencia VARCHAR(100), -- Nro. factura, orden, etc.
                                        usuario_id BIGINT NOT NULL,
                                        costo_unitario NUMERIC(12,2),
                                        observaciones TEXT,

                                        CONSTRAINT fk_movimiento_producto FOREIGN KEY (producto_id)
                                            REFERENCES productos(id_producto),
                                        CONSTRAINT fk_movimiento_proveedor FOREIGN KEY (proveedor_id)
                                            REFERENCES proveedores(id_proveedor),
                                        CONSTRAINT fk_movimiento_usuario FOREIGN KEY (usuario_id)
                                            REFERENCES usuarios(id_usuario),
                                        CONSTRAINT chk_cantidad CHECK (cantidad > 0),
                                        CONSTRAINT chk_tipo_movimiento CHECK (tipo_movimiento IN ('IN', 'OUT', 'AJUSTE', 'MERMA'))
);

COMMENT ON TABLE movimientos_inventario IS 'Registro de entradas y salidas de inventario';

-- Tabla: alertas_inventario
CREATE TABLE alertas_inventario (
                                    id_alerta BIGSERIAL PRIMARY KEY,
                                    producto_id BIGINT NOT NULL,
                                    nivel_stock INTEGER NOT NULL,
                                    fecha_generada TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    mensaje TEXT NOT NULL,
                                    estado VARCHAR(30) DEFAULT 'PENDIENTE', -- 'PENDIENTE', 'RESUELTA'
                                    fecha_resolucion TIMESTAMP WITH TIME ZONE,

                                    CONSTRAINT fk_alerta_producto FOREIGN KEY (producto_id)
                                        REFERENCES productos(id_producto) ON DELETE CASCADE,
                                    CONSTRAINT chk_estado_alerta CHECK (estado IN ('PENDIENTE', 'RESUELTA'))
);

COMMENT ON TABLE alertas_inventario IS 'Alertas de stock bajo o crítico';

-- Tabla: reportes_inventario
CREATE TABLE reportes_inventario (
                                     id_reporte BIGSERIAL PRIMARY KEY,
                                     tipo VARCHAR(50) NOT NULL, -- 'STOCK_VALORIZADO', 'MOVIMIENTOS', 'ALERTAS'
                                     fecha_generacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                     parametros JSONB,
                                     usuario_id BIGINT NOT NULL,
                                     ruta_archivo VARCHAR(500),

                                     CONSTRAINT fk_reporte_usuario FOREIGN KEY (usuario_id)
                                         REFERENCES usuarios(id_usuario)
);

COMMENT ON TABLE reportes_inventario IS 'Historial de reportes generados';

-- Índices para Gestión de Inventario
CREATE INDEX idx_productos_sku ON productos(sku);
CREATE INDEX idx_productos_nombre ON productos(nombre);
CREATE INDEX idx_productos_tipo ON productos(tipo, activo);
CREATE INDEX idx_movimientos_producto ON movimientos_inventario(producto_id);
CREATE INDEX idx_movimientos_fecha ON movimientos_inventario(fecha DESC);
CREATE INDEX idx_movimientos_tipo ON movimientos_inventario(tipo_movimiento);
CREATE INDEX idx_alertas_producto ON alertas_inventario(producto_id);
CREATE INDEX idx_alertas_estado ON alertas_inventario(estado);


-- ============================================
-- SECCIÓN 4: GESTIÓN DE CITAS Y PRESTACIÓN DE SERVICIOS
-- ============================================
-- ============================================
-- MÓDULO 4: GESTIÓN DE CITAS
-- ============================================

-- Tabla: citas
CREATE TABLE citas (
                       id_cita BIGSERIAL PRIMARY KEY,
                       paciente_id BIGINT NOT NULL,
                       veterinario_id BIGINT NOT NULL,
                       fecha_hora TIMESTAMP WITH TIME ZONE NOT NULL,
                       tipo_servicio VARCHAR(50) NOT NULL, -- 'consulta', 'cirugia', 'vacunacion', 'control'
                       estado VARCHAR(30) NOT NULL DEFAULT 'PROGRAMADA', -- 'PROGRAMADA', 'CANCELADA', 'REALIZADA', 'EN_CURSO'
                       motivo TEXT NOT NULL,
                       triage_nivel VARCHAR(30), -- 'BAJO', 'MEDIO', 'ALTO', 'URGENTE'
                       observaciones TEXT,
                       fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                       fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                       CONSTRAINT fk_cita_paciente FOREIGN KEY (paciente_id)
                           REFERENCES pacientes(id_paciente),
                       CONSTRAINT fk_cita_veterinario FOREIGN KEY (veterinario_id)
                           REFERENCES veterinarios(id_veterinario),
                       CONSTRAINT chk_estado_cita CHECK (estado IN ('PROGRAMADA', 'CANCELADA', 'REALIZADA', 'EN_CURSO')),
                       CONSTRAINT chk_triage CHECK (triage_nivel IN ('BAJO', 'MEDIO', 'ALTO', 'URGENTE'))
);

COMMENT ON TABLE citas IS 'Citas programadas entre pacientes y veterinarios';

-- Índice para evitar doble reserva
CREATE UNIQUE INDEX idx_citas_veterinario_fecha
    ON citas(veterinario_id, fecha_hora)
    WHERE estado = 'PROGRAMADA';

-- ============================================
-- MÓDULO 5: PRESTACIÓN DE SERVICIOS
-- ============================================

-- Tabla: servicios
CREATE TABLE servicios (
                           id_servicio BIGSERIAL PRIMARY KEY,
                           nombre VARCHAR(120) NOT NULL,
                           descripcion TEXT,
                           tipo VARCHAR(50) NOT NULL, -- 'consulta', 'cirugia', 'vacunacion', 'control', 'emergencia'
                           precio_base NUMERIC(12,2) NOT NULL,
                           duracion_min INTEGER, -- Duración estimada en minutos
                           activo BOOLEAN DEFAULT TRUE,
                           fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                           fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                           CONSTRAINT chk_precio_servicio CHECK (precio_base >= 0)
);

COMMENT ON TABLE servicios IS 'Catálogo de servicios ofrecidos';

-- Tabla: servicios_prestados
CREATE TABLE servicios_prestados (
                                     id_prestado BIGSERIAL PRIMARY KEY,
                                     cita_id BIGINT NOT NULL,
                                     servicio_id BIGINT NOT NULL,
                                     fecha_ejecucion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                     observaciones TEXT,
                                     costo_total NUMERIC(12,2) NOT NULL,
                                     descuento NUMERIC(5,2) DEFAULT 0, -- Porcentaje de descuento
                                     insumos_consumidos JSONB, -- [{producto_id: 1, cantidad: 2, precio_unitario: 10.50}, ...]

                                     CONSTRAINT fk_prestado_cita FOREIGN KEY (cita_id)
                                         REFERENCES citas(id_cita),
                                     CONSTRAINT fk_prestado_servicio FOREIGN KEY (servicio_id)
                                         REFERENCES servicios(id_servicio),
                                     CONSTRAINT chk_costo CHECK (costo_total >= 0),
                                     CONSTRAINT chk_descuento CHECK (descuento >= 0 AND descuento <= 100)
);

COMMENT ON TABLE servicios_prestados IS 'Registro de servicios ejecutados';
COMMENT ON COLUMN servicios_prestados.insumos_consumidos IS 'Detalle de insumos usados en el servicio';

-- Tabla: facturas
CREATE TABLE facturas (
                          id_factura BIGSERIAL PRIMARY KEY,
                          numero VARCHAR(50) NOT NULL UNIQUE, -- Formato: FAC-YYYY-NNNN
                          fecha_emision TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                          total NUMERIC(14,2) NOT NULL,
                          subtotal NUMERIC(14,2) NOT NULL,
                          impuestos NUMERIC(14,2) DEFAULT 0,
                          forma_pago VARCHAR(50) NOT NULL, -- 'EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CREDITO'
                          estado VARCHAR(20) NOT NULL DEFAULT 'EMITIDA', -- 'EMITIDA', 'PAGADA', 'ANULADA'
                          cliente_id BIGINT NOT NULL,
                          servicio_prestado_id BIGINT,
                          contenido JSONB, -- Detalle completo de la factura
                          fecha_pago TIMESTAMP WITH TIME ZONE,
                          observaciones TEXT,

                          CONSTRAINT fk_factura_cliente FOREIGN KEY (cliente_id)
                              REFERENCES clientes(id_cliente),
                          CONSTRAINT fk_factura_servicio FOREIGN KEY (servicio_prestado_id)
                              REFERENCES servicios_prestados(id_prestado),
                          CONSTRAINT chk_total CHECK (total >= 0),
                          CONSTRAINT chk_estado_factura CHECK (estado IN ('EMITIDA', 'PAGADA', 'ANULADA')),
                          CONSTRAINT chk_forma_pago CHECK (forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CREDITO'))
);

COMMENT ON TABLE facturas IS 'Facturas emitidas por servicios prestados';
COMMENT ON COLUMN facturas.numero IS 'Número único de factura (formato: FAC-YYYY-NNNN)';

-- Índices para Citas y Servicios
CREATE INDEX idx_citas_paciente ON citas(paciente_id);
CREATE INDEX idx_citas_veterinario ON citas(veterinario_id);
CREATE INDEX idx_citas_fecha ON citas(fecha_hora);
CREATE INDEX idx_citas_estado ON citas(estado);
CREATE INDEX idx_servicios_tipo ON servicios(tipo, activo);
CREATE INDEX idx_prestados_cita ON servicios_prestados(cita_id);
CREATE INDEX idx_prestados_servicio ON servicios_prestados(servicio_id);
CREATE INDEX idx_facturas_numero ON facturas(numero);
CREATE INDEX idx_facturas_cliente ON facturas(cliente_id);
CREATE INDEX idx_facturas_estado ON facturas(estado);
CREATE INDEX idx_facturas_fecha ON facturas(fecha_emision DESC);

-- ============================================
-- SECCIÓN 5: GESTIÓN DE NOTIFICACIONES
-- ============================================
-- ============================================
-- MÓDULO 6: GESTIÓN DE NOTIFICACIONES
-- ============================================

-- Tabla: canales_envio
CREATE TABLE canales_envio (
                               id_canal BIGSERIAL PRIMARY KEY,
                               nombre VARCHAR(50) NOT NULL UNIQUE,
                               tipo VARCHAR(20) NOT NULL, -- 'EMAIL', 'SMS', 'APP'
                               configuracion JSONB NOT NULL, -- {smtp_server: "...", port: 587, ...}
                               activo BOOLEAN DEFAULT TRUE,
                               fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                               fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                               CONSTRAINT chk_tipo_canal CHECK (tipo IN ('EMAIL', 'SMS', 'APP'))
);

COMMENT ON TABLE canales_envio IS 'Canales de envío de notificaciones (Strategy pattern)';

-- Tabla: plantillas_mensaje
CREATE TABLE plantillas_mensaje (
                                    id_plantilla BIGSERIAL PRIMARY KEY,
                                    nombre VARCHAR(100) NOT NULL UNIQUE,
                                    asunto VARCHAR(150),
                                    cuerpo TEXT NOT NULL,
                                    variables JSONB, -- ["nombre_cliente", "fecha_cita", ...]
                                    canal_tipo VARCHAR(20) NOT NULL, -- 'EMAIL', 'SMS', 'APP'
                                    activo BOOLEAN DEFAULT TRUE,
                                    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                                    CONSTRAINT chk_plantilla_canal CHECK (canal_tipo IN ('EMAIL', 'SMS', 'APP'))
);

COMMENT ON TABLE plantillas_mensaje IS 'Plantillas reutilizables para mensajes';
COMMENT ON COLUMN plantillas_mensaje.variables IS 'Variables que se reemplazarán en el mensaje';

-- Tabla: notificaciones
CREATE TABLE notificaciones (
                                id_notificacion BIGSERIAL PRIMARY KEY,
                                tipo VARCHAR(50) NOT NULL, -- 'RECORDATORIO_CITA', 'RECORDATORIO_VACUNA', 'ALERTA_INVENTARIO', 'FACTURA_EMITIDA'
                                mensaje TEXT NOT NULL,
                                fecha_envio_programada TIMESTAMP WITH TIME ZONE,
                                fecha_envio_real TIMESTAMP WITH TIME ZONE,
                                estado VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE', -- 'PENDIENTE', 'ENVIADA', 'FALLIDA', 'PROGRAMADA'
                                plantilla_id BIGINT,
                                canal_id BIGINT NOT NULL,
                                datos JSONB, -- Datos para renderizar la plantilla
                                intentos_envio INTEGER DEFAULT 0,
                                error_mensaje TEXT,

                                CONSTRAINT fk_notificacion_plantilla FOREIGN KEY (plantilla_id)
                                    REFERENCES plantillas_mensaje(id_plantilla),
                                CONSTRAINT fk_notificacion_canal FOREIGN KEY (canal_id)
                                    REFERENCES canales_envio(id_canal),
                                CONSTRAINT chk_estado_notif CHECK (estado IN ('PENDIENTE', 'ENVIADA', 'FALLIDA', 'PROGRAMADA'))
);

COMMENT ON TABLE notificaciones IS 'Notificaciones enviadas o programadas';

-- Tabla: destinatarios
CREATE TABLE destinatarios (
                               id_destinatario BIGSERIAL PRIMARY KEY,
                               notificacion_id BIGINT NOT NULL,
                               tipo_destinatario VARCHAR(30) NOT NULL, -- 'USUARIO', 'CLIENTE', 'VETERINARIO'
                               referencia_id BIGINT NOT NULL, -- ID del usuario/cliente/veterinario
                               canal_preferido VARCHAR(50),
                               fecha_lectura TIMESTAMP WITH TIME ZONE,

                               CONSTRAINT fk_destinatario_notificacion FOREIGN KEY (notificacion_id)
                                   REFERENCES notificaciones(id_notificacion) ON DELETE CASCADE,
                               CONSTRAINT chk_tipo_destinatario CHECK (tipo_destinatario IN ('USUARIO', 'CLIENTE', 'VETERINARIO'))
);

COMMENT ON TABLE destinatarios IS 'Destinatarios de notificaciones';

-- Índices para Notificaciones
CREATE INDEX idx_notificaciones_estado ON notificaciones(estado);
CREATE INDEX idx_notificaciones_programada ON notificaciones(fecha_envio_programada) WHERE estado = 'PROGRAMADA';
CREATE INDEX idx_notificaciones_tipo ON notificaciones(tipo);
CREATE INDEX idx_destinatarios_notificacion ON destinatarios(notificacion_id);
CREATE INDEX idx_destinatarios_referencia ON destinatarios(tipo_destinatario, referencia_id);


-- ============================================
-- SECCIÓN 6: CONFIGURACIÓN DEL SISTEMA Y REPORTES
-- ============================================
-- ============================================
-- MÓDULO 7: CONFIGURACIÓN DEL SISTEMA
-- ============================================

-- Tabla: parametros_sistema (Singleton pattern)
CREATE TABLE parametros_sistema (
                                    id_parametro BIGSERIAL PRIMARY KEY,
                                    clave VARCHAR(150) NOT NULL UNIQUE,
                                    valor VARCHAR(500) NOT NULL,
                                    descripcion TEXT,
                                    aplicacion VARCHAR(50), -- 'NOTIFICACIONES', 'INVENTARIO', 'GLOBAL'
                                    tipo_dato VARCHAR(30) DEFAULT 'STRING', -- 'STRING', 'INTEGER', 'BOOLEAN', 'JSON'
                                    ultima_modificacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    modificado_por BIGINT,

                                    CONSTRAINT fk_parametro_usuario FOREIGN KEY (modificado_por)
                                        REFERENCES usuarios(id_usuario)
);

COMMENT ON TABLE parametros_sistema IS 'Parámetros de configuración del sistema (Singleton)';
COMMENT ON COLUMN parametros_sistema.clave IS 'Clave única del parámetro (ej: STOCK_MINIMO_ALERTA)';

-- Tabla: backups_sistema
CREATE TABLE backups_sistema (
                                 id_backup BIGSERIAL PRIMARY KEY,
                                 fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                 ruta_archivo VARCHAR(255) NOT NULL,
                                 tamanio_mb NUMERIC(10,2),
                                 estado VARCHAR(30) NOT NULL DEFAULT 'COMPLETADO', -- 'EN_PROCESO', 'COMPLETADO', 'FALLIDO'
                                 metadata JSONB,
                                 creado_por BIGINT,

                                 CONSTRAINT fk_backup_usuario FOREIGN KEY (creado_por)
                                     REFERENCES usuarios(id_usuario),
                                 CONSTRAINT chk_estado_backup CHECK (estado IN ('EN_PROCESO', 'COMPLETADO', 'FALLIDO'))
);

COMMENT ON TABLE backups_sistema IS 'Historial de backups del sistema';

-- Tabla: logs_sistema
CREATE TABLE logs_sistema (
                              id_log BIGSERIAL PRIMARY KEY,
                              fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                              nivel VARCHAR(20) NOT NULL, -- 'ERROR', 'WARN', 'INFO', 'DEBUG'
                              componente VARCHAR(100) NOT NULL, -- 'INVENTARIO', 'NOTIFICACIONES', etc.
                              mensaje TEXT NOT NULL,
                              metadata JSONB,
                              usuario_id BIGINT,
                              ip_address VARCHAR(45),

                              CONSTRAINT fk_log_usuario FOREIGN KEY (usuario_id)
                                  REFERENCES usuarios(id_usuario),
                              CONSTRAINT chk_nivel_log CHECK (nivel IN ('ERROR', 'WARN', 'INFO', 'DEBUG'))
);

COMMENT ON TABLE logs_sistema IS 'Logs de eventos del sistema';

-- Tabla: configuraciones_notificacion
CREATE TABLE configuraciones_notificacion (
                                              id_config BIGSERIAL PRIMARY KEY,
                                              canal_id BIGINT NOT NULL,
                                              activo BOOLEAN DEFAULT TRUE,
                                              parametros JSONB NOT NULL, -- {api_key: "...", remitente: "...", ...}
                                              fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                              actualizado_por BIGINT,

                                              CONSTRAINT fk_config_canal FOREIGN KEY (canal_id)
                                                  REFERENCES canales_envio(id_canal),
                                              CONSTRAINT fk_config_usuario FOREIGN KEY (actualizado_por)
                                                  REFERENCES usuarios(id_usuario)
);

COMMENT ON TABLE configuraciones_notificacion IS 'Configuraciones específicas de canales de notificación';

-- ============================================
-- MÓDULO 8: REPORTES Y ESTADÍSTICAS (Facade)
-- ============================================

-- Tabla: reportes
CREATE TABLE reportes (
                          id_reporte BIGSERIAL PRIMARY KEY,
                          nombre VARCHAR(120) NOT NULL,
                          tipo VARCHAR(50) NOT NULL, -- 'CITAS_MENSUALES', 'INVENTARIO_VALORIZADO', 'FACTURACION_PERIODO'
                          fecha_generacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                          generado_por BIGINT NOT NULL,
                          parametros JSONB, -- {fecha_inicio: "2024-01-01", fecha_fin: "2024-12-31"}
                          ruta_archivo VARCHAR(500),
                          formato VARCHAR(20), -- 'PDF', 'EXCEL', 'CSV'

                          CONSTRAINT fk_reporte_usuario FOREIGN KEY (generado_por)
                              REFERENCES usuarios(id_usuario)
);

COMMENT ON TABLE reportes IS 'Historial de reportes generados (Facade pattern)';

-- Tabla: estadisticas
CREATE TABLE estadisticas (
                              id_estadistica BIGSERIAL PRIMARY KEY,
                              nombre VARCHAR(120) NOT NULL,
                              valor NUMERIC(18,4) NOT NULL,
                              periodo_inicio DATE NOT NULL,
                              periodo_fin DATE NOT NULL,
                              tipo_calculo VARCHAR(50), -- 'SUMA', 'PROMEDIO', 'CONTEO', 'PORCENTAJE'
                              metadata JSONB,
                              fecha_calculo TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE estadisticas IS 'Estadísticas calculadas del sistema';

-- Tabla: indicadores
CREATE TABLE indicadores (
                             id_indicador BIGSERIAL PRIMARY KEY,
                             nombre VARCHAR(120) NOT NULL UNIQUE,
                             descripcion TEXT,
                             valor_actual NUMERIC(18,4) NOT NULL,
                             valor_objetivo NUMERIC(18,4),
                             unidad_medida VARCHAR(30), -- '%', '$', 'unidades', 'minutos'
                             color_semaforo VARCHAR(20), -- 'VERDE', 'AMARILLO', 'ROJO'
                             fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

                             CONSTRAINT chk_color CHECK (color_semaforo IN ('VERDE', 'AMARILLO', 'ROJO'))
);

COMMENT ON TABLE indicadores IS 'Indicadores clave del negocio (KPIs)';

-- Tabla: fuentes_datos
CREATE TABLE fuentes_datos (
                               id_fuente BIGSERIAL PRIMARY KEY,
                               nombre VARCHAR(120) NOT NULL UNIQUE,
                               tipo VARCHAR(50) NOT NULL, -- 'BD', 'CSV', 'API'
                               configuracion JSONB NOT NULL,
                               query_sql TEXT, -- Query SQL si tipo = 'BD'
                               activo BOOLEAN DEFAULT TRUE,
                               fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE fuentes_datos IS 'Fuentes de datos para reportes';

-- Índices para Configuración y Reportes
CREATE INDEX idx_parametros_clave ON parametros_sistema(clave);
CREATE INDEX idx_parametros_aplicacion ON parametros_sistema(aplicacion);
CREATE INDEX idx_logs_fecha ON logs_sistema(fecha_hora DESC);
CREATE INDEX idx_logs_nivel ON logs_sistema(nivel);
CREATE INDEX idx_logs_componente ON logs_sistema(componente);
CREATE INDEX idx_reportes_tipo ON reportes(tipo);
CREATE INDEX idx_reportes_fecha ON reportes(fecha_generacion DESC);
CREATE INDEX idx_estadisticas_periodo ON estadisticas(periodo_inicio, periodo_fin);


-- ============================================
-- SECCIÓN 7: DATOS INICIALES (SEED DATA)
-- ============================================
-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar roles predefinidos
INSERT INTO roles (nombre_rol, descripcion) VALUES
                                                ('ADMIN', 'Administrador del sistema con acceso completo'),
                                                ('VETERINARIO', 'Veterinario con acceso a gestión clínica'),
                                                ('SECRETARIO', 'Secretario/recepcionista con acceso administrativo'),
                                                ('CLIENTE', 'Cliente con acceso limitado a su información');

-- Insertar permisos básicos
INSERT INTO permisos (nombre, descripcion, recurso, accion) VALUES
-- Usuarios
('USUARIOS_CREAR', 'Crear usuarios', 'USUARIOS', 'CREATE'),
('USUARIOS_LEER', 'Leer usuarios', 'USUARIOS', 'READ'),
('USUARIOS_ACTUALIZAR', 'Actualizar usuarios', 'USUARIOS', 'UPDATE'),
('USUARIOS_ELIMINAR', 'Eliminar usuarios', 'USUARIOS', 'DELETE'),

-- Pacientes
('PACIENTES_CREAR', 'Crear pacientes', 'PACIENTES', 'CREATE'),
('PACIENTES_LEER', 'Leer pacientes', 'PACIENTES', 'READ'),
('PACIENTES_ACTUALIZAR', 'Actualizar pacientes', 'PACIENTES', 'UPDATE'),
('PACIENTES_ELIMINAR', 'Eliminar pacientes', 'PACIENTES', 'DELETE'),

-- Citas
('CITAS_CREAR', 'Crear citas', 'CITAS', 'CREATE'),
('CITAS_LEER', 'Leer citas', 'CITAS', 'READ'),
('CITAS_ACTUALIZAR', 'Actualizar citas', 'CITAS', 'UPDATE'),
('CITAS_CANCELAR', 'Cancelar citas', 'CITAS', 'CANCEL'),

-- Inventario
('INVENTARIO_CREAR', 'Crear productos', 'INVENTARIO', 'CREATE'),
('INVENTARIO_LEER', 'Leer inventario', 'INVENTARIO', 'READ'),
('INVENTARIO_ACTUALIZAR', 'Actualizar inventario', 'INVENTARIO', 'UPDATE'),
('INVENTARIO_ELIMINAR', 'Eliminar productos', 'INVENTARIO', 'DELETE'),

-- Servicios y Facturación
('SERVICIOS_CREAR', 'Crear servicios', 'SERVICIOS', 'CREATE'),
('SERVICIOS_LEER', 'Leer servicios', 'SERVICIOS', 'READ'),
('FACTURAS_CREAR', 'Crear facturas', 'FACTURAS', 'CREATE'),
('FACTURAS_LEER', 'Leer facturas', 'FACTURAS', 'READ'),
('FACTURAS_ANULAR', 'Anular facturas', 'FACTURAS', 'CANCEL'),

-- Reportes
('REPORTES_GENERAR', 'Generar reportes', 'REPORTES', 'CREATE'),
('REPORTES_LEER', 'Ver reportes', 'REPORTES', 'READ'),

-- Configuración
('CONFIG_ACTUALIZAR', 'Actualizar configuración', 'CONFIGURACION', 'UPDATE'),
('CONFIG_LEER', 'Leer configuración', 'CONFIGURACION', 'READ');

-- Asignar permisos a roles

-- ADMIN: Todos los permisos
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT 1, id_permiso FROM permisos;

-- VETERINARIO: Permisos clínicos
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT 2, id_permiso FROM permisos
WHERE recurso IN ('PACIENTES', 'CITAS', 'SERVICIOS', 'FACTURAS', 'INVENTARIO')
  AND accion IN ('CREATE', 'READ', 'UPDATE');

-- SECRETARIO: Permisos administrativos
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT 3, id_permiso FROM permisos
WHERE recurso IN ('PACIENTES', 'CITAS', 'INVENTARIO', 'FACTURAS')
  AND accion IN ('CREATE', 'READ', 'UPDATE', 'CANCEL');

-- CLIENTE: Solo lectura de su información
INSERT INTO rol_permiso (rol_id, permiso_id)
SELECT 4, id_permiso FROM permisos
WHERE recurso IN ('PACIENTES', 'CITAS', 'FACTURAS')
  AND accion = 'READ';

-- Insertar usuario administrador por defecto
-- Password: Admin123! (debe cambiarse en primera ejecución)
INSERT INTO usuarios (username, password_hash, activo, rol_id, tipo_usuario, nombre, apellido, correo, telefono)
VALUES (
           'admin',
           '$2a$12$AlmF5UyMMp7HD1V4AZ/7EuDTlhhOOOEtR3iR8vfC.yXgzy7ctlbOC', -- BCrypt hash de "JOHANfelipe12345"
           TRUE,
           1, -- Rol ADMIN
           'VETERINARIO',
           'Administrador',
           'Sistema',
           'admin@veterinaria.com',
           '3001234567'
       );

-- Insertar parámetros del sistema
INSERT INTO parametros_sistema (clave, valor, descripcion, aplicacion, tipo_dato) VALUES
                                                                                      ('STOCK_MINIMO_ALERTA', '10', 'Stock mínimo para generar alerta', 'INVENTARIO', 'INTEGER'),
                                                                                      ('DURACION_CONSULTA_DEFAULT', '30', 'Duración por defecto de consulta en minutos', 'CITAS', 'INTEGER'),
                                                                                      ('IVA_PORCENTAJE', '19', 'Porcentaje de IVA aplicado', 'FACTURACION', 'INTEGER'),
                                                                                      ('DIAS_RECORDATORIO_CITA', '1', 'Días de anticipación para recordatorio de cita', 'NOTIFICACIONES', 'INTEGER'),
                                                                                      ('EMAIL_REMITENTE', 'noreply@veterinaria.com', 'Email remitente por defecto', 'NOTIFICACIONES', 'STRING'),
                                                                                      ('HORARIO_APERTURA', '08:00', 'Horario de apertura de la clínica', 'GLOBAL', 'STRING'),
                                                                                      ('HORARIO_CIERRE', '18:00', 'Horario de cierre de la clínica', 'GLOBAL', 'STRING');

-- Insertar canal de email por defecto
INSERT INTO canales_envio (nombre, tipo, configuracion, activo) VALUES
    ('Email Principal', 'EMAIL', '{"smtp_server": "smtp.gmail.com", "port": 587, "use_tls": true}', TRUE);

-- Insertar plantillas básicas
INSERT INTO plantillas_mensaje (nombre, asunto, cuerpo, variables, canal_tipo) VALUES
    ('RECORDATORIO_CITA',
     'Recordatorio: Cita programada para {{nombre_paciente}}',
     'Estimado/a {{nombre_cliente}},\n\nLe recordamos que tiene una cita programada para {{nombre_paciente}} el día {{fecha_cita}} a las {{hora_cita}}.\n\nVeterinario: Dr. {{nombre_veterinario}}\nMotivo: {{motivo}}\n\n¡Le esperamos!\n\nClínica Veterinaria',
     '["nombre_cliente", "nombre_paciente", "fecha_cita", "hora_cita", "nombre_veterinario", "motivo"]'::jsonb,
     'EMAIL');

-- Insertar algunos indicadores base
INSERT INTO indicadores (nombre, descripcion, valor_actual, valor_objetivo, unidad_medida, color_semaforo) VALUES
                                                                                                               ('Tasa de ocupación', 'Porcentaje de citas ocupadas vs disponibles', 0, 80, '%', 'VERDE'),
                                                                                                               ('Ingreso promedio por consulta', 'Promedio de ingresos por consulta', 0, 50000, '$', 'VERDE'),
                                                                                                               ('Satisfacción del cliente', 'Nivel de satisfacción promedio', 0, 4.5, 'puntos', 'VERDE');
-- ============================================
-- FIN DEL SCRIPT DE MIGRACIÓN V1
-- ============================================
