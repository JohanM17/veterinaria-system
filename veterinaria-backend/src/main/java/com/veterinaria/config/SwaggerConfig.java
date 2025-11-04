package com.veterinaria.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuración de Swagger/OpenAPI
 *
 * Genera documentación interactiva de la API en:
 * http://localhost:8080/api/swagger-ui.html
 *
 * Incluye:
 * - Listado de todos los endpoints
 * - Botón "Authorize" para agregar token JWT
 * - Interfaz para probar endpoints sin Postman
 */
@Configuration
public class SwaggerConfig {

    /**
     * Configura la documentación OpenAPI
     *
     * @return OpenAPI configurado
     */
    @Bean
    public OpenAPI customOpenAPI() {
        // Nombre del esquema de seguridad
        final String securitySchemeName = "bearerAuth";

        return new OpenAPI()
                // Información general de la API
                .info(new Info()
                        .title("API Sistema Veterinaria")
                        .description("Sistema de gestión integral para clínicas veterinarias")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("Equipo Veterinaria")
                                .email("contacto@veterinaria.com")
                                .url("https://github.com/JohanM17/veterinaria-system")
                        )
                        .license(new License()
                                .name("Proyecto Académico")
                                .url("https://github.com/JohanM17/veterinaria-system")
                        )
                )

                // Configurar seguridad JWT
                .addSecurityItem(new SecurityRequirement()
                        .addList(securitySchemeName)
                )

                .components(new Components()
                        .addSecuritySchemes(securitySchemeName, new SecurityScheme()
                                .name(securitySchemeName)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Ingrese el token JWT (sin 'Bearer ')")
                        )
                );
    }
}