
// Note: tasksProvider commented out as getTasks method was removed from ApiService
// Implement this endpoint if needed
/*
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final apiService = ApiService();
  final response = await apiService.getTasks();
  
  if (response.data != null && response.data is List) {
    return (response.data as List)
        .map((json) => Task.fromJson(json))
        .toList();
  }
  
  return [];
});
*/
