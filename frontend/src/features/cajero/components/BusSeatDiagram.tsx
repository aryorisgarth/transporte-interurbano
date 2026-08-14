import { Box, Tooltip } from '@mui/material';
import type { AsientoViaje } from '@/shared/api';
import { ETIQUETAS_ESTADO_ASIENTO, esAsientoTrasera, esAsientoVentana, etiquetaPosicionAsiento } from '@/shared/utils/formato';
import { seatColors } from '@/shared/theme';

export const YUTONG_BUS_FOTO = '/images/bus-yutong-interurbano.png';

/** ViewBox ancho — Yutong interurbano 2 columnas */
function dims(compact: boolean) {
  return {
    BLOCK_H: compact ? 48 : 62,
    ROW_GAP: compact ? 6 : 8,
    COL_GAP: compact ? 22 : 28,
    PAD: compact ? 22 : 28,
    PAD_TOP: compact ? 92 : 118,
    PAD_BOTTOM: compact ? 26 : 32,
    COL_W: compact ? 178 : 228,
    BUS_RADIUS: compact ? 18 : 22,
    INNER_GAP: compact ? 6 : 8,
  };
}

interface Props {
  asientos: AsientoViaje[];
  seleccionados: number[];
  onToggle?: (viajeAsientoId: number) => void;
  modoSeleccion?: boolean;
  fillContainer?: boolean;
  busMarca?: string;
  busFotoUrl?: string | null;
  busNumeroInterno?: string | null;
  compact?: boolean;
}

function colorAsiento(asiento: AsientoViaje, seleccionado: boolean): string {
  if (seleccionado) return '#1565c0';
  return seatColors[asiento.estado] ?? '#9e9e9e';
}

function puedeClic(asiento: AsientoViaje, modoSeleccion: boolean) {
  return modoSeleccion && asiento.estado === 'DISPONIBLE';
}

function SeatSlot({
  asiento,
  x,
  y,
  w,
  h,
  seleccionado,
  modoSeleccion,
  onToggle,
  compact = false,
}: {
  asiento: AsientoViaje;
  x: number;
  y: number;
  w: number;
  h: number;
  seleccionado: boolean;
  modoSeleccion: boolean;
  onToggle?: () => void;
  compact?: boolean;
}) {
  const fill = colorAsiento(asiento, seleccionado);
  const esV = esAsientoVentana(asiento.posicion);
  const tooltip = `#${asiento.numero} · ${etiquetaPosicionAsiento(asiento.posicion)} · ${ETIQUETAS_ESTADO_ASIENTO[asiento.estado]}`;
  const fontNum = Math.max(compact ? 12 : 16, Math.min(compact ? 20 : 26, w * 0.48));
  const fontTag = Math.max(compact ? 8 : 10, Math.min(compact ? 11 : 14, w * 0.24));

  const slot = (
    <Box
      component="g"
      onClick={() => puedeClic(asiento, modoSeleccion) && onToggle?.()}
      onMouseDown={(e: React.MouseEvent) => e.preventDefault()}
      sx={{ cursor: puedeClic(asiento, modoSeleccion) ? 'pointer' : 'default' }}
    >
      <rect
        x={x}
        y={y}
        width={w}
        height={h}
        rx={10}
        fill={fill}
        stroke={seleccionado ? '#0d47a1' : 'rgba(255,255,255,0.4)'}
        strokeWidth={seleccionado ? 3 : 1.5}
      />
      <text
        x={x + w / 2}
        y={y + h / 2 + 3}
        textAnchor="middle"
        fill="#fff"
        fontSize={fontNum}
        fontWeight={800}
        fontFamily="Roboto, sans-serif"
        style={{ pointerEvents: 'none' }}
      >
        {asiento.numero}
      </text>
      <text
        x={x + w / 2}
        y={y + h - 8}
        textAnchor="middle"
        fill="rgba(255,255,255,0.95)"
        fontSize={fontTag}
        fontWeight={700}
        fontFamily="Roboto, sans-serif"
        style={{ pointerEvents: 'none' }}
      >
        {esV ? 'V' : 'P'}
      </text>
      {esV && (
        <rect
          x={x + 5}
          y={y + 6}
          width={5}
          height={h - 14}
          rx={2.5}
          fill="rgba(255,255,255,0.35)"
          style={{ pointerEvents: 'none' }}
        />
      )}
    </Box>
  );

  return <Tooltip title={tooltip}>{slot}</Tooltip>;
}

function BloquePar({
  par,
  x,
  y,
  w,
  h,
  seleccionados,
  modoSeleccion,
  onToggle,
  compact = false,
  innerGap = 8,
}: {
  par: AsientoViaje[];
  x: number;
  y: number;
  w: number;
  h: number;
  seleccionados: number[];
  modoSeleccion: boolean;
  onToggle?: (id: number) => void;
  compact?: boolean;
  innerGap?: number;
}) {
  const n = par.length;
  const slotW = n > 0 ? (w - innerGap * (n - 1) - 8) / n : w;

  return (
    <g>
      <rect
        x={x}
        y={y}
        width={w}
        height={h}
        rx={14}
        fill="#43a047"
        fillOpacity={0.15}
        stroke="#2e7d32"
        strokeWidth={2.5}
      />
      {par.map((asiento, i) => (
        <g key={asiento.viajeAsientoId}>
          {i > 0 && (
            <line
              x1={x + 4 + i * slotW + (i - 1) * innerGap + innerGap / 2}
              y1={y + 10}
              x2={x + 4 + i * slotW + (i - 1) * innerGap + innerGap / 2}
              y2={y + h - 10}
              stroke="rgba(46,125,50,0.5)"
              strokeWidth={2}
              strokeDasharray="5 4"
            />
          )}
          <SeatSlot
            asiento={asiento}
            x={x + 4 + i * (slotW + innerGap)}
            y={y + 4}
            w={slotW}
            h={h - 8}
            seleccionado={seleccionados.includes(asiento.viajeAsientoId)}
            modoSeleccion={modoSeleccion}
            onToggle={() => onToggle?.(asiento.viajeAsientoId)}
            compact={compact}
          />
        </g>
      ))}
    </g>
  );
}

function agruparPares(asientos: AsientoViaje[]): AsientoViaje[][] {
  const cabina = asientos
    .filter((a) => !esAsientoTrasera(a.posicion))
    .sort((a, b) => a.numero - b.numero);

  const pares: AsientoViaje[][] = [];
  for (let i = 0; i < cabina.length; i += 2) {
    const par = [cabina[i]];
    if (cabina[i + 1]) par.push(cabina[i + 1]);
    pares.push(par);
  }
  return pares;
}

function grillaDosColumnas(pares: AsientoViaje[][]) {
  const filas: { izq?: AsientoViaje[]; der?: AsientoViaje[] }[] = [];
  for (let i = 0; i < pares.length; i += 2) {
    filas.push({ izq: pares[i], der: pares[i + 1] });
  }
  return filas;
}

export function BusSeatDiagram({
  asientos,
  seleccionados,
  onToggle,
  modoSeleccion = false,
  fillContainer = true,
  busMarca = 'Yutong',
  busFotoUrl,
  busNumeroInterno,
  compact = false,
}: Props) {
  const {
    BLOCK_H,
    ROW_GAP,
    COL_GAP,
    PAD,
    PAD_TOP,
    PAD_BOTTOM,
    COL_W,
    BUS_RADIUS,
    INNER_GAP,
  } = dims(compact);
  const fontBrand = compact ? 22 : 28;
  const fontSub = compact ? 10 : 12;
  const fotoBus = busFotoUrl || YUTONG_BUS_FOTO;
  const trasera = asientos.filter((a) => esAsientoTrasera(a.posicion)).sort((a, b) => a.numero - b.numero);
  const pares = agruparPares(asientos);
  const filas = grillaDosColumnas(pares);

  const busW = PAD * 2 + COL_W * 2 + COL_GAP;
  const aisleX = PAD + COL_W + COL_GAP / 2;
  const filasH = filas.length * (BLOCK_H + ROW_GAP);
  const traseraH = trasera.length > 0 ? BLOCK_H + 32 : 0;
  const busH = PAD_TOP + filasH + traseraH + PAD_BOTTOM;
  const contentBottom = PAD_TOP + filasH + traseraH;

  return (
    <Box
      sx={{
        width: '100%',
        flex: fillContainer ? 1 : undefined,
        minHeight: fillContainer ? { xs: 440, md: 500 } : undefined,
        height: fillContainer ? '100%' : 'auto',
        display: 'flex',
        alignItems: 'stretch',
        justifyContent: 'center',
      }}
    >
      <svg
        viewBox={`0 0 ${busW} ${busH}`}
        preserveAspectRatio="xMidYMin meet"
        aria-label="Mapa de asientos del bus"
        style={{
          width: '100%',
          maxWidth: '100%',
          height: 'auto',
          minHeight: compact ? 300 : 380,
          display: 'block',
        }}
      >
        <defs>
          <linearGradient id="busBodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#fafafa" />
            <stop offset="8%" stopColor="#ffffff" />
            <stop offset="100%" stopColor="#eceff1" />
          </linearGradient>
          <linearGradient id="windowBandGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#37474f" stopOpacity={0.85} />
            <stop offset="100%" stopColor="#546e7a" stopOpacity={0.5} />
          </linearGradient>
          <linearGradient id="windshieldGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#455a64" stopOpacity={0.9} />
            <stop offset="100%" stopColor="#263238" stopOpacity={0.7} />
          </linearGradient>
          <clipPath id="yutongCabinaClip">
            <path d={`M ${busW * 0.08} 38 Q ${busW / 2} 14 ${busW * 0.92} 38 L ${busW * 0.88} 108 L ${busW * 0.12} 108 Z`} />
          </clipPath>
        </defs>

        {/* Carrocería blanca tipo coach interurbano */}
        <rect x={2} y={2} width={busW - 4} height={busH - 4} rx={BUS_RADIUS} fill="url(#busBodyGrad)" stroke="#b0bec5" strokeWidth={2.5} />

        {/* Franja de ventanas laterales */}
        <rect x={8} y={10} width={busW - 16} height={22} rx={6} fill="url(#windowBandGrad)" opacity={0.35} />

        {/* Cabina Yutong — foto + parabrisas */}
        <path
          d={`M ${busW * 0.08} 38 Q ${busW / 2} 14 ${busW * 0.92} 38 L ${busW * 0.88} 108 L ${busW * 0.12} 108 Z`}
          fill="url(#windshieldGrad)"
          stroke="#37474f"
          strokeWidth={1.5}
        />
        <image
          href={fotoBus}
          x={busW * 0.12}
          y={42}
          width={busW * 0.76}
          height={62}
          preserveAspectRatio="xMidYMid slice"
          clipPath="url(#yutongCabinaClip)"
          opacity={0.92}
        />
        <rect x={busW * 0.12} y={38} width={busW * 0.76} height={72} fill="rgba(255,255,255,0.55)" />
        <text
          x={busW / 2}
          y={72}
          textAnchor="middle"
          fill="#003087"
          fontSize={fontBrand}
          fontWeight={900}
          fontFamily="Roboto, Arial, sans-serif"
          letterSpacing={4}
        >
          {busMarca.toUpperCase()}
        </text>
        <text x={busW / 2} y={92} textAnchor="middle" fill="#455a64" fontSize={fontSub} fontWeight={600} fontFamily="Roboto, sans-serif">
          Interurbano{busNumeroInterno ? ` · Bus ${busNumeroInterno}` : ''} · {asientos.length} asientos
        </text>

        {/* Pasillo central ancho */}
        <rect x={aisleX - COL_GAP / 2 + 2} y={PAD_TOP - 6} width={COL_GAP - 4} height={contentBottom - PAD_TOP + 10} rx={4} fill="#f5f5f5" stroke="#cfd8dc" strokeWidth={1} />
        <line
          x1={aisleX}
          y1={PAD_TOP - 2}
          x2={aisleX}
          y2={contentBottom}
          stroke="#90a4ae"
          strokeWidth={2}
          strokeDasharray="10 7"
        />

        <text x={PAD + COL_W / 2} y={PAD_TOP - 12} textAnchor="middle" fill="#455a64" fontSize={11} fontWeight={700} fontFamily="Roboto, sans-serif">
          IZQUIERDA
        </text>
        <text x={PAD + COL_W + COL_GAP + COL_W / 2} y={PAD_TOP - 12} textAnchor="middle" fill="#455a64" fontSize={11} fontWeight={700} fontFamily="Roboto, sans-serif">
          DERECHA
        </text>

        {filas.map((fila, idx) => {
          const y = PAD_TOP + idx * (BLOCK_H + ROW_GAP);
          return (
            <g key={idx}>
              {fila.izq && (
                <BloquePar
                  par={fila.izq}
                  x={PAD}
                  y={y}
                  w={COL_W}
                  h={BLOCK_H}
                  seleccionados={seleccionados}
                  modoSeleccion={modoSeleccion}
                  onToggle={onToggle}
                  compact={compact}
                  innerGap={INNER_GAP}
                />
              )}
              {fila.der && (
                <BloquePar
                  par={fila.der}
                  x={PAD + COL_W + COL_GAP}
                  y={y}
                  w={COL_W}
                  h={BLOCK_H}
                  seleccionados={seleccionados}
                  modoSeleccion={modoSeleccion}
                  onToggle={onToggle}
                  compact={compact}
                  innerGap={INNER_GAP}
                />
              )}
            </g>
          );
        })}

        {trasera.length > 0 && (
          <g>
            <text
              x={busW / 2}
              y={PAD_TOP + filasH + 16}
              textAnchor="middle"
              fill="#455a64"
              fontSize={11}
              fontWeight={700}
              fontFamily="Roboto, sans-serif"
            >
              FILA TRASERA · 46 – 50
            </text>
            <BloquePar
              par={trasera}
              x={PAD}
              y={PAD_TOP + filasH + 20}
              w={COL_W * 2 + COL_GAP}
              h={BLOCK_H}
              seleccionados={seleccionados}
              modoSeleccion={modoSeleccion}
              onToggle={onToggle}
              compact={compact}
              innerGap={INNER_GAP}
            />
          </g>
        )}

        <polygon
          points={`${busW / 2 - 12},${busH - 6} ${busW / 2 + 12},${busH - 6} ${busW / 2},${busH - 24}`}
          fill="#78909c"
        />
        <text x={busW / 2} y={busH - 28} textAnchor="middle" fill="#78909c" fontSize={10} fontWeight={600} fontFamily="Roboto, sans-serif">
          FRENTE DEL BUS
        </text>
      </svg>
    </Box>
  );
}
