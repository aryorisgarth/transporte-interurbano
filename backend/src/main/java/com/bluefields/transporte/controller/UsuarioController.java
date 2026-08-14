package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.usuario.ActualizarOperadorRequest;
import com.bluefields.transporte.dto.usuario.CrearOperadorRequest;
import com.bluefields.transporte.dto.usuario.UsuarioResponse;
import com.bluefields.transporte.security.OperadorContext;
import com.bluefields.transporte.service.OperadorService;
import com.bluefields.transporte.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final OperadorService operadorService;
    private final OperadorContext operadorContext;

    public UsuarioController(
            UsuarioService usuarioService,
            OperadorService operadorService,
            OperadorContext operadorContext
    ) {
        this.usuarioService = usuarioService;
        this.operadorService = operadorService;
        this.operadorContext = operadorContext;
    }

    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> perfilActual() {
        var operador = operadorContext.resolverOperador(null);
        return ResponseEntity.ok(usuarioService.perfilActual(operador.getId()));
    }

    @GetMapping
    public ResponseEntity<List<UsuarioResponse>> listarOperadores(
            @RequestParam(required = false) Long empresaId
    ) {
        return ResponseEntity.ok(operadorService.listarPorEmpresa(empresaId));
    }

    @PostMapping
    public ResponseEntity<UsuarioResponse> crearOperador(@Valid @RequestBody CrearOperadorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(operadorService.crear(request));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<UsuarioResponse> actualizarOperador(
            @PathVariable Long id,
            @Valid @RequestBody ActualizarOperadorRequest request
    ) {
        return ResponseEntity.ok(operadorService.actualizar(id, request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponse> obtener(@PathVariable Long id) {
        return usuarioService.buscar(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
