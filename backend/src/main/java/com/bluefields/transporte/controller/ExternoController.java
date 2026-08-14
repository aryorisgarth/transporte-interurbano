package com.bluefields.transporte.controller;

import com.bluefields.transporte.dto.externo.TarifaReferenciaUsdResponse;
import com.bluefields.transporte.dto.externo.TipoCambioResponse;
import com.bluefields.transporte.service.externo.TipoCambioExternoService;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/externo")
@Validated
public class ExternoController {

    private final TipoCambioExternoService tipoCambioExternoService;

    public ExternoController(TipoCambioExternoService tipoCambioExternoService) {
        this.tipoCambioExternoService = tipoCambioExternoService;
    }

    @GetMapping("/tipo-cambio/usd")
    public ResponseEntity<TipoCambioResponse> tipoCambioUsd() {
        return ResponseEntity.ok(tipoCambioExternoService.obtenerTipoCambioUsd());
    }

    @GetMapping("/tarifa-referencia-usd")
    public ResponseEntity<TarifaReferenciaUsdResponse> tarifaReferenciaUsd(
            @RequestParam @NotNull @DecimalMin("0.0") BigDecimal monto
    ) {
        return ResponseEntity.ok(tipoCambioExternoService.convertirTarifaAUsd(monto));
    }
}
