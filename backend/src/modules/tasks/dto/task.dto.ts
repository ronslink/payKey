export enum TaskPriority {
  HIGH = 'High',
  MEDIUM = 'Medium',
  LOW = 'Low',
}

export class TaskDto {
  id: string;
  title: string;
  description: string;
  dueDate: Date;
  priority: TaskPriority;
  actionUrl: string; // Frontend route to navigate to
  type: 'payroll' | 'tax' | 'leave' | 'worker';
}
