import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionPlansPage extends ConsumerWidget {
  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select the perfect plan for managing your domestic workers',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Free Plan
            _PlanCard(
              tier: 'FREE',
              name: 'Free',
              subtitle: 'Perfect for getting started with one worker',
              priceUSD: 0,
              priceKES: 0,
              features: const [
                'Up to 1 worker',
                'Automatic tax calculations',
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Basic Plan (Most Popular)
            _PlanCard(
              tier: 'BASIC',
              name: 'Basic',
              subtitle: 'Essential features for managing up to 5 workers',
              priceUSD: 9.99,
              priceKES: 1200,
              features: const [
                'Up to 5 workers',
                'Automatic tax calculations',
                'M-Pesa payments',
                'Leave tracking',
              ],
              isPopular: true,
            ),
            
            const SizedBox(height: 16),
            
            // Gold Plan
            _PlanCard(
              tier: 'GOLD',
              name: 'Gold',
              subtitle: 'Advanced features for growing teams',
              priceUSD: 29.99,
              priceKES: 3600,
              features: const [
                'Up to 10 workers',
                'Automatic tax calculations',
                'M-Pesa payments',
                'Leave tracking',
                'Advanced reporting',
                'Priority support',
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Platinum Plan
            _PlanCard(
              tier: 'PLATINUM',
              name: 'Platinum',
              subtitle: 'Complete solution with KRA automation and integrations',
              priceUSD: 49.99,
              priceKES: 6000,
              features: const [
                'Up to 15 workers',
                'Automatic tax calculations',
                'M-Pesa payments',
                'Leave tracking',
                'Time tracking (clock in/out)',
                'Geofencing',
                'Automatic tax payments to KRA',
                'Finance software integration',
                'Multi-property management',
              ],
            ),
            
            const SizedBox(height: 24),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('All plans include 14-day free trial'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Cancel anytime'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String tier;
  final String name;
  final String subtitle;
  final double priceUSD;
  final double priceKES;
  final List<String> features;
  final bool isPopular;

  const _PlanCard({
    required this.tier,
    required this.name,
    required this.subtitle,
    required this.priceUSD,
    required this.priceKES,
    required this.features,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPopular
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      priceUSD.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '/monthly',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'or KES ${priceKES.toStringAsFixed(0)} via M-Pesa',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement subscription selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected $name plan')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.blue : null,
                      foregroundColor: isPopular ? Colors.white : null,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(tier == 'FREE' ? 'Get Started' : 'Start Free Trial'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
