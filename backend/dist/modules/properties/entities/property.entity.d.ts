import { User } from '../../users/entities/user.entity';
import { Worker } from '../../workers/entities/worker.entity';
export declare class Property {
    id: string;
    user: User;
    userId: string;
    name: string;
    address: string;
    latitude: number;
    longitude: number;
    geofenceRadius: number;
    isActive: boolean;
    workers: Worker[];
    createdAt: Date;
    updatedAt: Date;
}
