import { Venue, VenueType, GoOrganizacion } from '../models/types';
import { apiClient } from './apiClient';
import { authService } from './authService';
import { MOCK_VENUES } from '../data/mock/venues';

class VenueService {
  private mockVenues: Venue[] = [...MOCK_VENUES];

  async getVenues(): Promise<Venue[]> {
    if (authService.isDemo()) {
      return [...this.mockVenues];
    }

    const orgs = await apiClient.get<GoOrganizacion[]>('/organizaciones');
    return orgs.map(this.mapGoOrganizacionToVenue);
  }

  async getVenueById(id: string): Promise<Venue | undefined> {
    if (authService.isDemo()) {
      return this.mockVenues.find(v => v.id === id);
    }

    const numId = parseInt(id.replace('ven-', ''), 10);
    const org = await apiClient.get<GoOrganizacion>(`/organizaciones/${numId || id}`);
    return this.mapGoOrganizacionToVenue(org);
  }

  async createVenue(venueData: {
    nombre: string;
    direccion: string;
    tipo: VenueType;
    latitud: number;
    longitud: number;
    radioMetros: number;
    estado?: string;
  }): Promise<Venue> {
    if (authService.isDemo()) {
      const newVenue: Venue = {
        id: `ven-${Date.now()}`,
        nombre: venueData.nombre,
        direccion: venueData.direccion,
        tipo: venueData.tipo,
        latitud: venueData.latitud,
        longitud: venueData.longitud,
        radioMetros: venueData.radioMetros || 80,
        estado: 'ACTIVO',
        talleresActivosCount: 0,
      };
      this.mockVenues.unshift(newVenue);
      return newVenue;
    }

    const payload = {
      nombre: venueData.nombre,
      tipo: venueData.tipo,
      sector_ubicacion: venueData.direccion,
      latitud: venueData.latitud,
      longitud: venueData.longitud,
      radio_metros: venueData.radioMetros || 80,
    };

    const res = await apiClient.post<{ id: number }>('/organizaciones', payload);
    return {
      id: res.id.toString(),
      numericId: res.id,
      nombre: venueData.nombre,
      direccion: venueData.direccion,
      tipo: venueData.tipo,
      latitud: venueData.latitud,
      longitud: venueData.longitud,
      radioMetros: venueData.radioMetros || 80,
      estado: 'ACTIVO',
    };
  }

  async updateVenue(id: string, updates: Partial<Venue>): Promise<Venue | null> {
    if (authService.isDemo()) {
      const index = this.mockVenues.findIndex(v => v.id === id);
      if (index === -1) return null;
      this.mockVenues[index] = { ...this.mockVenues[index], ...updates };
      return this.mockVenues[index];
    }

    const numId = parseInt(id.replace('ven-', ''), 10) || id;
    const existing = await apiClient.get<GoOrganizacion>(`/organizaciones/${numId}`);

    const payload = {
      id: existing.id,
      nombre: updates.nombre ?? existing.nombre,
      tipo: updates.tipo ?? existing.tipo,
      sector_ubicacion: updates.direccion ?? existing.sector_ubicacion,
      latitud: updates.latitud ?? existing.latitud,
      longitud: updates.longitud ?? existing.longitud,
      radio_metros: updates.radioMetros ?? existing.radio_metros,
    };

    await apiClient.put(`/organizaciones/${numId}`, payload);
    return this.mapGoOrganizacionToVenue({ ...existing, ...payload });
  }

  async deleteVenue(id: string): Promise<boolean> {
    if (authService.isDemo()) {
      this.mockVenues = this.mockVenues.filter(v => v.id !== id);
      return true;
    }

    const numId = parseInt(id.replace('ven-', ''), 10) || id;
    await apiClient.delete(`/organizaciones/${numId}`);
    return true;
  }

  async toggleVenueStatus(id: string): Promise<Venue | null> {
    if (authService.isDemo()) {
      const venue = this.mockVenues.find(v => v.id === id);
      if (!venue) return null;
      venue.estado = venue.estado === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO';
      return venue;
    }

    // In Go backend organizations do not have a dedicated activo column, status is represented as active
    return this.getVenueById(id).then(v => v || null);
  }

  private mapGoOrganizacionToVenue(org: GoOrganizacion): Venue {
    return {
      id: org.id.toString(),
      numericId: org.id,
      nombre: org.nombre,
      direccion: org.sector_ubicacion,
      tipo: org.tipo as VenueType,
      latitud: org.latitud ?? -13.5186,
      longitud: org.longitud ?? -71.9839,
      radioMetros: org.radio_metros || 80,
      estado: 'ACTIVO',
    };
  }
}

export const venueService = new VenueService();
