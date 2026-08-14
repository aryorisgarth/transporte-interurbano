# -*- coding: utf-8 -*-
"""Genera el PDF actualizado del sistema de transporte."""
from fpdf import FPDF
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Sistema de Gestion de Transporte Interurbano Bluefields.pdf"


class PDF(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 14)
        self.cell(0, 10, "Sistema de Gestion de Transporte Interurbano", ln=True, align="C")
        self.set_font("Helvetica", "", 11)
        self.cell(0, 6, "Bluefields - Managua", ln=True, align="C")
        self.ln(4)

    def section(self, title: str):
        self.set_font("Helvetica", "B", 12)
        self.cell(0, 8, title, ln=True)
        self.ln(2)

    def body(self, text: str):
        self.set_font("Helvetica", "", 10)
        width = self.w - self.l_margin - self.r_margin
        self.multi_cell(width, 5, text)
        self.ln(2)

    def bullet_list(self, items: list[str]):
        self.set_font("Helvetica", "", 10)
        width = self.w - self.l_margin - self.r_margin
        for item in items:
            self.multi_cell(width, 5, f"  - {item}")
        self.ln(2)


def main():
    pdf = PDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    pdf.section("Problema")
    pdf.body(
        "Las empresas de transporte en la ruta Bluefields - Managua administran la venta de "
        "boletos de forma manual mediante cuadernos. Los pasajeros deben desplazarse a la terminal, "
        "las lineas telefonicas no responden y no existe informacion en tiempo real sobre cupos. "
        "En temporadas altas se generan largas filas y aglomeraciones."
    )

    pdf.section("Objetivo")
    pdf.body(
        "Digitalizar la gestion de viajes permitiendo consultar disponibilidad en tiempo real, "
        "administrar viajes y controlar la ocupacion de buses desde una plataforma centralizada "
        "multiempresa, manteniendo la venta presencial en terminal como regla principal."
    )

    pdf.section("Regla principal: sin reservas")
    pdf.bullet_list([
        "No existe pre-reserva como flujo normal del sistema.",
        "El pasajero debe ir a la terminal a comprar el boleto el dia anterior o el mismo dia del viaje.",
        "La consulta publica muestra horarios y cupos disponibles; no aparta asientos.",
        "Excepcion: un permiso especial (RESERVA_EXCEPCIONAL) permite apartar asiento solo en casos autorizados.",
        "El sistema es escalable, pero la regla de no reservar siempre prevalece por defecto.",
    ])

    pdf.section("Tipo de plataforma")
    pdf.body(
        "Plataforma multiempresa: una sola plataforma para Wendelyn, Martinez y otras empresas. "
        "Cada empresa accede solo a sus datos. Los pasajeros consultan viajes de todas las empresas."
    )

    pdf.section("Actores del sistema")
    pdf.body("Pasajero (publico): consultar horarios, empresas, asientos libres.")
    pdf.body("Operador/Cajero: vender boletos, asignar asientos, registrar equipaje extra, gestionar viajes del dia.")
    pdf.body("Administrador de empresa: crear buses, programar viajes, gestionar operadores, reportes.")
    pdf.body("Administrador general: registrar empresas, supervisar operaciones, reportes globales.")

    pdf.add_page()
    pdf.section("Modelo de asientos y tarifas")
    pdf.bullet_list([
        "Layout: 2 filas; cada fila tiene asiento de ventana y asiento de pasillo, numerados secuencialmente.",
        "Tarifa unica: un boleto es un boleto, sin tarifa especial para ninos.",
        "Compra multiple valida: una persona puede comprar varios boletos a su nombre (ej. familia de 5).",
        "Identificacion (cedula) solo del comprador al momento de la venta.",
        "En el boleto impreso: nombre del comprador y lista de asientos (ej. Asientos 1 al 5).",
    ])

    pdf.section("Equipaje")
    pdf.bullet_list([
        "Cada boleto incluye derecho a 1 equipaje mediano o pequeno.",
        "Equipaje adicional genera cargo extra en la misma venta.",
    ])

    pdf.section("Modulos del sistema")
    pdf.bullet_list([
        "Gestion de empresas: nombre, telefono, correo, estado.",
        "Gestion de buses: numero interno, placa, capacidad, layout de asientos.",
        "Gestion de viajes: origen, destino, fecha, hora, bus, tarifa, estado.",
        "Gestion de asientos por viaje: disponible, vendido, cancelado, reservado excepcional.",
        "Gestion de ventas y boletos: comprador, asientos, totales, equipaje extra.",
        "Consulta publica: origen, destino, fecha; muestra horarios, empresa y cupos libres.",
    ])

    pdf.section("Estados")
    pdf.body("Asiento por viaje: DISPONIBLE, VENDIDO, CANCELADO, RESERVADO_EXCEPCIONAL.")
    pdf.body("Venta: COMPLETADA, CANCELADA, PARCIALMENTE_CANCELADA.")
    pdf.body("Boleto: ACTIVO, CANCELADO.")

    pdf.section("Fases de implementacion")
    pdf.body("Fase 1 (MVP): empresas, buses, viajes, asientos, ventas en terminal, consulta publica, panel admin, multiempresa.")
    pdf.body("Fase 2: notificaciones, historial, reportes avanzados.")
    pdf.body("Fase 3: pago en linea, boleto digital, codigo QR (sin cambiar regla de no reservar por defecto).")
    pdf.body("Fase 4: gestion de encomiendas y seguimiento de paquetes.")

    pdf.add_page()
    pdf.section("Tecnologias")
    pdf.bullet_list([
        "Frontend: React, Material UI (fase posterior).",
        "Backend: Spring Boot (Java 17).",
        "Base de datos: MySQL.",
        "Seguridad: Keycloak (integracion futura).",
        "Infraestructura: Docker.",
        "Documentacion API: Swagger/OpenAPI.",
    ])

    pdf.section("Estructura del proyecto")
    pdf.body("backend/ - API REST Spring Boot, logica de negocio, base de datos.")
    pdf.body("frontend/ - Aplicacion React (desarrollo posterior).")

    pdf.output(str(OUTPUT))
    print(f"PDF generado: {OUTPUT}")


if __name__ == "__main__":
    main()
