package com.veterinaria.config;

import com.veterinaria.common.exception.UnauthorizedException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Filtro de autenticación JWT
 * Se ejecuta en CADA petición HTTP antes del controller
 *
 * Responsabilidades:
 * 1. Extraer token del header Authorization
 * 2. Validar el token
 * 3. Cargar usuario en el contexto de seguridad
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private UserDetailsService userDetailsService;

    /**
     * Método principal que intercepta cada request
     */
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        try {
            // 1. Extraer token del header
            String token = getTokenFromRequest(request);

            // 2. Si hay token y es válido
            if (StringUtils.hasText(token) && jwtTokenProvider.validateToken(token)) {

                // 3. Extraer username del token
                String username = jwtTokenProvider.getUsernameFromToken(token);

                // 4. Cargar usuario completo de la BD
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                // 5. Crear objeto de autenticación
                UsernamePasswordAuthenticationToken authenticationToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                authenticationToken.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                );

                // 6. Establecer autenticación en el contexto de seguridad
                SecurityContextHolder.getContext().setAuthentication(authenticationToken);
            }

        } catch (UnauthorizedException ex) {
            // Si el token es inválido, no hacer nada
            // El GlobalExceptionHandler se encargará del error
            SecurityContextHolder.clearContext();
        }

        // 7. Continuar con el siguiente filtro o controller
        filterChain.doFilter(request, response);
    }

    /**
     * Extrae el token JWT del header Authorization
     *
     * @param request HTTP request
     * @return Token JWT sin el prefijo "Bearer "
     */
    private String getTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");

        // Verificar que el header exista y comience con "Bearer "
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7); // Quitar "Bearer " (7 caracteres)
        }

        return null;
    }
}
