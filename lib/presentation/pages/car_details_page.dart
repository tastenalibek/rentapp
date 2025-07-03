
import 'package:flutter/material.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/pages/MapsDetailsPage.dart';
import 'package:rentapp/presentation/widgets/car_card.dart';
import 'package:rentapp/presentation/widgets/more_card.dart';

class CardDetailsPage extends StatefulWidget {
  final Car car;

  const CardDetailsPage({super.key, required this.car});

  @override
  State<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_controller!)
      ..addListener(() {
        setState(() {});
      });

    _controller!.forward();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info_outline),
            Text(' Information')
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarCard(car: widget.car),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        children: const [
                          CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/user.png')),
                          SizedBox(height: 10),
                          Text('Jane Cooper', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('\$4,253', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapsDetailsPage(car: widget.car)),
                        );
                      },
                      child: Container(
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Transform.scale(
                                scale: _animation!.value,
                                alignment: Alignment.center,
                                child: Image.asset('assets/maps.png', fit: BoxFit.cover),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.bottomCenter,
                                padding: const EdgeInsets.all(12),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map, color: Colors.white, size: 18),
                                    SizedBox(width: 5),
                                    Text(
                                      'View on Map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                    child: Text(
                      'Similar Cars',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  MoreCard(car: widget.car.copyWith(model: widget.car.model + "-1", distance: widget.car.distance + 10, fuelCapacity: widget.car.fuelCapacity + 100, pricePerHour: widget.car.pricePerHour + 10, image: widget.car.image)),
                  const SizedBox(height: 10),
                  MoreCard(car: widget.car.copyWith(model: widget.car.model + "-2", distance: widget.car.distance + 20, fuelCapacity: widget.car.fuelCapacity + 200, pricePerHour: widget.car.pricePerHour + 20, image: widget.car.image)),
                  const SizedBox(height: 10),
                  MoreCard(car: widget.car.copyWith(model: widget.car.model + "-3", distance: widget.car.distance + 30, fuelCapacity: widget.car.fuelCapacity + 300, pricePerHour: widget.car.pricePerHour + 30, image: widget.car.image)),
                  const SizedBox(height: 10),
                  MoreCard(car: widget.car.copyWith(model: widget.car.model + "-4", distance: widget.car.distance + 40, fuelCapacity: widget.car.fuelCapacity + 340, pricePerHour: widget.car.pricePerHour + 37, image: widget.car.image)),
                  const SizedBox(height: 10),
                  MoreCard(car: widget.car.copyWith(model: widget.car.model + "-5", distance: widget.car.distance + 40, fuelCapacity: widget.car.fuelCapacity + 410, pricePerHour: widget.car.pricePerHour + 41, image: widget.car.image)),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapsDetailsPage(car: widget.car)),
          );
        },
        label: const Text('Navigate'),
        icon: const Icon(Icons.directions),
      ),
    );
  }
}
