export declare class CreatePropertyDto {
    name: string;
    address: string;
    latitude?: number;
    longitude?: number;
    geofenceRadius?: number;
}
export declare class UpdatePropertyDto {
    name?: string;
    address?: string;
    latitude?: number;
    longitude?: number;
    geofenceRadius?: number;
    isActive?: boolean;
}
export declare class PropertySummaryDto {
    id: string;
    name: string;
    address: string;
    workerCount: number;
    isActive: boolean;
}
