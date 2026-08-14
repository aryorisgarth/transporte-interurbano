import { Link as RouterLink } from 'react-router-dom';
import { Box, Button, Typography } from '@mui/material';
import HomeIcon from '@mui/icons-material/Home';
import SearchIcon from '@mui/icons-material/Search';
import { PageHeader } from '@/shared/ui/PageHeader';

export default function NotFound() {
  return (
    <Box>
      <PageHeader
        title="404"
        subtitle="La página que busca no existe o fue movida."
      />
      <Box textAlign="center" py={4}>
        <Typography variant="h6" color="text.secondary" gutterBottom>
          Página no encontrada
        </Typography>
        <Box display="flex" gap={2} justifyContent="center" flexWrap="wrap" sx={{ mt: 2 }}>
          <Button component={RouterLink} to="/" variant="contained" startIcon={<HomeIcon />}>
            Volver al inicio
          </Button>
          <Button component={RouterLink} to="/consulta" variant="outlined" startIcon={<SearchIcon />}>
            Consultar viajes
          </Button>
        </Box>
      </Box>
    </Box>
  );
}
