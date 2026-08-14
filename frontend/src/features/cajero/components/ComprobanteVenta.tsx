import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Typography,
} from '@mui/material';
import PrintIcon from '@mui/icons-material/Print';
import PictureAsPdfIcon from '@mui/icons-material/PictureAsPdf';
import type { VentaResponse } from '@/shared/api';
import { formatearCordobas } from '@/shared/utils/formato';
import { descargarComprobantePdf } from '@/shared/utils/comprobantePdf';

interface Props {
  open: boolean;
  venta: VentaResponse | null;
  viajeInfo?: { origen: string; destino: string; fecha: string; hora: string; empresa: string };
  onClose: () => void;
}

export function ComprobanteVenta({ open, venta, viajeInfo, onClose }: Props) {
  if (!venta) return null;

  function imprimir() {
    window.print();
  }

  function descargarPdf() {
    if (!venta) return;
    descargarComprobantePdf(venta, viajeInfo);
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Comprobante de venta</DialogTitle>
      <DialogContent id="comprobante-venta">
        <Box className="comprobante-print" sx={{ p: 1 }}>
          <Typography variant="h6" align="center" gutterBottom>
            {viajeInfo?.empresa ?? 'Transporte Interurbano'}
          </Typography>
          <Typography align="center" color="text.secondary" variant="body2" gutterBottom>
            Bluefields – Managua
          </Typography>
          <Divider sx={{ my: 2 }} />
          <Typography variant="body2">
            <strong>Código:</strong> {venta.codigo}
          </Typography>
          {viajeInfo && (
            <Typography variant="body2">
              <strong>Viaje:</strong> {viajeInfo.origen} → {viajeInfo.destino} · {viajeInfo.fecha}{' '}
              {viajeInfo.hora}
            </Typography>
          )}
          <Typography variant="body2" sx={{ mt: 1 }}>
            <strong>Comprador:</strong> {venta.compradorNombre}
          </Typography>
          <Typography variant="body2">
            <strong>Cédula:</strong> {venta.compradorCedula}
          </Typography>
          <Typography variant="body2" sx={{ mt: 1 }}>
            <strong>Asientos:</strong> {venta.numerosAsiento.join(', ')}
          </Typography>
          <Divider sx={{ my: 2 }} />
          <Typography variant="body2">
            Boletos: {formatearCordobas(Number(venta.subtotalBoletos))}
          </Typography>
          {Number(venta.subtotalEquipaje) > 0 && (
            <Typography variant="body2">
              Equipaje extra: {formatearCordobas(Number(venta.subtotalEquipaje))}
            </Typography>
          )}
          <Typography variant="h6" sx={{ mt: 1 }}>
            Total: {formatearCordobas(Number(venta.total))}
          </Typography>
          <Typography variant="caption" display="block" sx={{ mt: 2 }} color="text.secondary">
            1 equipaje incluido por boleto. Presente este comprobante en terminal.
          </Typography>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cerrar</Button>
        <Button startIcon={<PictureAsPdfIcon />} onClick={descargarPdf}>
          Descargar PDF
        </Button>
        <Button variant="contained" startIcon={<PrintIcon />} onClick={imprimir}>
          Imprimir
        </Button>
      </DialogActions>
    </Dialog>
  );
}
