import { useEffect, useState } from 'react';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  CircularProgress,
  TextField,
  Typography,
} from '@mui/material';
import SaveIcon from '@mui/icons-material/Save';
import { actualizarEmpresa, miEmpresa, obtenerEmpresa, type Empresa } from '@/shared/api';

interface Props {
  token: string;
  empresaId: number;
  esGlobal?: boolean;
  onActualizado?: (empresa: Empresa) => void;
}

export function PerfilEmpresaForm({ token, empresaId, esGlobal = false, onActualizado }: Props) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [nombre, setNombre] = useState('');
  const [telefono, setTelefono] = useState('');
  const [correo, setCorreo] = useState('');
  const [tarifaEquipaje, setTarifaEquipaje] = useState(100);
  const [logoUrl, setLogoUrl] = useState('');

  useEffect(() => {
    async function cargar() {
      setLoading(true);
      setMsg(null);
      try {
        const e = esGlobal ? await obtenerEmpresa(token, empresaId) : await miEmpresa(token);
        setNombre(e.nombre);
        setTelefono(e.telefono ?? '');
        setCorreo(e.correo ?? '');
        setTarifaEquipaje(Number(e.tarifaEquipajeExtra));
        setLogoUrl(e.logoUrl ?? '');
      } catch {
        setMsg({ type: 'error', text: 'No se pudo cargar el perfil de la empresa' });
      } finally {
        setLoading(false);
      }
    }
    cargar();
  }, [token, empresaId, esGlobal]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setMsg(null);
    try {
      const actualizada = await actualizarEmpresa(token, empresaId, {
        nombre,
        telefono: telefono || undefined,
        correo: correo || undefined,
        tarifaEquipajeExtra: tarifaEquipaje,
        logoUrl: logoUrl || undefined,
      });
      setMsg({ type: 'success', text: 'Perfil actualizado' });
      onActualizado?.(actualizada);
    } catch (err) {
      setMsg({ type: 'error', text: err instanceof Error ? err.message : 'Error al guardar' });
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" py={4}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Card component="form" onSubmit={handleSubmit} sx={{ maxWidth: 560 }}>
      <CardContent>
        <Box display="flex" alignItems="center" gap={2} mb={2}>
          <Avatar src={logoUrl || undefined} alt={nombre} sx={{ width: 64, height: 64 }} />
          <Box>
            <Typography variant="h6">Perfil de la cooperativa</Typography>
            <Typography variant="body2" color="text.secondary">
              Datos comerciales y logo público — el correo aquí no es usuario de login
            </Typography>
          </Box>
        </Box>

        {msg && (
          <Alert severity={msg.type} sx={{ mb: 2 }}>
            {msg.text}
          </Alert>
        )}

        <TextField
          fullWidth
          required
          label="Nombre comercial"
          margin="dense"
          value={nombre}
          onChange={(e) => setNombre(e.target.value)}
        />
        <TextField
          fullWidth
          label="URL del logo"
          margin="dense"
          placeholder="https://..."
          helperText="Enlace a imagen (PNG/JPG) o use ui-avatars.com para demo"
          value={logoUrl}
          onChange={(e) => setLogoUrl(e.target.value)}
        />
        <TextField
          fullWidth
          label="Teléfono"
          margin="dense"
          value={telefono}
          onChange={(e) => setTelefono(e.target.value)}
        />
        <TextField
          fullWidth
          type="email"
          label="Correo de contacto (cooperativa)"
          margin="dense"
          value={correo}
          onChange={(e) => setCorreo(e.target.value)}
          helperText="Información comercial / consulta pública. No es el usuario para iniciar sesión."
        />
        <TextField
          fullWidth
          type="number"
          inputProps={{ min: 0, step: 1 }}
          label="Tarifa equipaje extra (C$)"
          margin="dense"
          value={tarifaEquipaje}
          onChange={(e) => setTarifaEquipaje(Number(e.target.value))}
        />

        <Button
          type="submit"
          variant="contained"
          startIcon={<SaveIcon />}
          sx={{ mt: 2 }}
          disabled={saving}
        >
          {saving ? 'Guardando…' : 'Guardar cambios'}
        </Button>
      </CardContent>
    </Card>
  );
}
