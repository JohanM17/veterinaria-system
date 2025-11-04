package com.veterinaria.config;

import com.veterinaria.common.exception.UnauthorizedException;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SignatureException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.stream.Collectors;

/**
 * Proveedor de tokens JWT
 * Responsabilidades:
 * 1. Generar tokens JWT al hacer login
 * 2. Validar tokens en cada request
 * 3. Extraer información del usuario del token
 */
@Component
public class JwtTokenProvider {

    @Value("${spring.security.jwt.secret-key}")
    private String jwtSecret;

    @Value("${spring.security.jwt.expiration-time}")
    private long jwtExpirationMs;

    /**
     * Genera un token JWT para un usuario autenticado
     *
     * @param authentication Objeto con datos del usuario autenticado
     * @return Token JWT como String
     */
    public String generateToken(Authentication authentication) {
        String username = authentication.getName();
        Date currentDate = new Date();
        Date expiryDate = new Date(currentDate.getTime() + jwtExpirationMs);

        // Extraer roles del usuario
        String roles = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(","));

        // Crear el token
        return Jwts.builder()
                .subject(username) // Usuario (username)
                .claim("roles", roles) // Roles del usuario
                .issuedAt(currentDate) // Fecha de emisión
                .expiration(expiryDate) // Fecha de expiración
                .signWith(getSigningKey()) // Firma con clave secreta
                .compact();
    }

    /**
     * Extrae el username del token JWT
     *
     * @param token Token JWT
     * @return Username del usuario
     */
    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();
    }

    /**
     * Valida un token JWT
     *
     * @param token Token JWT
     * @return true si es válido, false si no
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token);
            return true;

        } catch (SignatureException ex) {
            throw new UnauthorizedException("Firma JWT inválida");
        } catch (MalformedJwtException ex) {
            throw new UnauthorizedException("Token JWT malformado");
        } catch (ExpiredJwtException ex) {
            throw new UnauthorizedException("Token JWT expirado");
        } catch (UnsupportedJwtException ex) {
            throw new UnauthorizedException("Token JWT no soportado");
        } catch (IllegalArgumentException ex) {
            throw new UnauthorizedException("JWT claims string está vacío");
        }
    }

    /**
     * Obtiene la clave secreta para firmar tokens
     *
     * @return SecretKey
     */
    private SecretKey getSigningKey() {
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}