import type { ReactNode } from 'react';
import { OperativeShell } from '@/shared/layout/OperativeShell';
import { ROLES } from '@/shared/utils/jwt';
import {
  AdminNav,
  type AdminSectionId,
  findNavItem,
  buildAdminNav,
} from '@/features/admin/components/AdminNav';

interface Props {
  esGlobal: boolean;
  section: AdminSectionId;
  onSectionChange: (id: AdminSectionId) => void;
  sidebarFooter?: ReactNode;
  topBarExtra?: ReactNode;
  children: ReactNode;
}

export function AdminShell({
  esGlobal,
  section,
  onSectionChange,
  sidebarFooter,
  topBarExtra,
  children,
}: Props) {
  const navGroups = buildAdminNav(esGlobal);
  const currentNav = findNavItem(navGroups, section);

  const footerLinks = [{ label: 'Consulta pública', to: '/consulta' }];

  return (
    <OperativeShell
      brandSubtitle={esGlobal ? 'Consola de plataforma' : 'Panel cooperativa'}
      role={esGlobal ? ROLES.ADMIN_GENERAL : ROLES.ADMIN_EMPRESA}
      title={currentNav?.label ?? 'Administración'}
      description={currentNav?.description}
      nav={
        <AdminNav
          variant="sidebar"
          section={section}
          onSectionChange={onSectionChange}
          esGlobal={esGlobal}
        />
      }
      sidebarFooter={sidebarFooter}
      topBarExtra={topBarExtra}
      footerLinks={footerLinks}
    >
      {children}
    </OperativeShell>
  );
}
