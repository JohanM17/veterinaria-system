package com.veterinaria.common.constants;

public class SecurityConstants {

    // JWT
    public static final String JWT_SECRET_KEY = "jwt.secret-key";
    public static final String JWT_EXPIRATION_TIME = "jwt.expiration-time";
    public static final String JWT_TOKEN_PREFIX = "Bearer ";
    public static final String JWT_HEADER_STRING = "Authorization";

    // Endpoints públicos (sin autenticación)
    public static final String[] PUBLIC_URLS = {
            "/api/auth/**",
            "/api/public/**",
            "/swagger-ui/**",
            "/v3/api-docs/**",
            "/swagger-resources/**",
            "/webjars/**"
    };

    // Roles
    public static final String ROLE_ADMIN = "ADMIN";
    public static final String ROLE_VETERINARIO = "VETERINARIO";
    public static final String ROLE_SECRETARIO = "SECRETARIO";
    public static final String ROLE_CLIENTE = "CLIENTE";

    private SecurityConstants() {
        // Prevenir instanciación
    }
}