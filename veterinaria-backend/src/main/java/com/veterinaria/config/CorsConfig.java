package com.veterinaria.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Configuración de CORS (Cross-Origin Resource Sharing)
 *
 * Permite que el frontend (React en puerto 3000) haga requests al backend (puerto 8080)
 *
 * Sin CORS: Navegador bloquea requests entre diferentes orígenes
 * Con CORS: Backend autoriza orígenes específicos
 */
@Configuration
public class CorsConfig {

    /**
     * Configura las reglas de CORS para toda la aplicación
     *
     * @return CorsConfigurationSource con las reglas
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // 1. Orígenes permitidos (URLs del frontend)
        configuration.setAllowedOrigins(Arrays.asList(
                "http://localhost:3000",      // React en desarrollo
                "http://localhost:5173",      // Vite (alternativa a React)
                "http://127.0.0.1:3000",      // Alternativa localhost
                "https://tu-dominio.com"      // Producción (cambiar cuando despliegues)
        ));

        // 2. Métodos HTTP permitidos
        configuration.setAllowedMethods(Arrays.asList(
                "GET",      // Obtener datos
                "POST",     // Crear datos
                "PUT",      // Actualizar datos completos
                "PATCH",    // Actualizar datos parciales
                "DELETE",   // Eliminar datos
                "OPTIONS"   // Preflight request (automático del navegador)
        ));

        // 3. Headers permitidos
        configuration.setAllowedHeaders(Arrays.asList(
                "Authorization",   // Para JWT token
                "Content-Type",    // Para JSON
                "Accept",          // Tipo de respuesta aceptada
                "X-Requested-With" // Identificar AJAX requests
        ));

        // 4. Permitir enviar credenciales (cookies, auth headers)
        configuration.setAllowCredentials(true);

        // 5. Headers que el frontend puede leer en la respuesta
        configuration.setExposedHeaders(Arrays.asList(
                "Authorization",     // Para devolver nuevo token
                "Content-Disposition" // Para descargas de archivos
        ));

        // 6. Tiempo que el navegador cachea la respuesta preflight (1 hora)
        configuration.setMaxAge(3600L);

        // 7. Aplicar configuración a todas las rutas
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}