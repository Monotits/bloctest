import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductRepository>(
      create: (context) => ProductRepository(),
      child: MaterialApp(
        title: 'Bloc Test App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePageOne(),
      ),
    );
    // return MaterialApp(
    //   home: MyHomePage(),
    // );
  }
}

class MyHomePageOne extends StatefulWidget {
  const MyHomePageOne({super.key});

  @override
  State<MyHomePageOne> createState() => _MyHomePageOneState();
}

class _MyHomePageOneState extends State<MyHomePageOne> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          child: const Text('Test'),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyHomePage()));
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Sort? sortButtonName;
  Filter? filterButtonName;

  @override
  void initState() {
    context.read<ProductRepository>().add(LoadEvent());
    print(mounted);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocBuilder<ProductRepository, ProductRepositoryState>(
            builder: (context, state) {
              print(state);
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 120,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          DropdownButton<Sort>(
                              value: sortButtonName,
                              items: Sort.values.map((Sort e) {
                                return DropdownMenuItem(value: e, child: Text(e.name.toString()));
                              }).toList(),
                              onChanged: ((value) {
                                setState(() {
                                  sortButtonName = value;
                                  context.read<ProductRepository>().add(SortEvent(SortField.id, value!));
                                });
                              })),
                          DropdownButton<Filter>(
                              value: filterButtonName,
                              items: Filter.values.map((Filter e) {
                                return DropdownMenuItem(value: e, child: Text(e.name.toString()));
                              }).toList(),
                              onChanged: ((value) {
                                setState(() {
                                  filterButtonName = value;
                                  context.read<ProductRepository>().add(FilterEvent(value!));
                                });
                              })),
                        ],
                      ),
                    ),
                    if (state is LoadingProductRepositoryState || state is IdleProductRepositoryState)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 150),
                        child: CircularProgressIndicator(
                          color: Colors.purple,
                        ),
                      ),
                    if (state is AllProductRepositoryState)
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(state.products[index].id.toString()),
                              subtitle: Text(state.products[index].price.toString()),
                            );
                          },
                        ),
                      ),
                    if (state is FilteredProductRepositoryState)
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(state.products[index].id.toString()),
                              subtitle: Text(state.products[index].price.toString()),
                            );
                          },
                        ),
                      ),
                    if (state is SortedProductRepositoryState)
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(state.products[index].id.toString()),
                              subtitle: Text(state.products[index].price.toString()),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

abstract class ProductRepositoryEvent {}

class FilterEvent extends ProductRepositoryEvent {
  final Filter filter;

  FilterEvent(this.filter);
}

class SortEvent extends ProductRepositoryEvent {
  final Sort sort;
  final SortField sortField;

  SortEvent(this.sortField, this.sort);
}

class RemoveOrderEvent extends ProductRepositoryEvent {
  RemoveOrderEvent();
}

class LoadEvent extends ProductRepositoryEvent {
  LoadEvent();
}

class RefreshEvent extends ProductRepositoryEvent {
  RefreshEvent();
}

abstract class ProductRepositoryState {
  ProductRepositoryState({this.sortField, this.filter, this.sort});

  bool get isLoading;

  SortField? sortField;

  Sort? sort;

  Filter? filter;

  bool get hasItems => !isLoading;
}

mixin ResultState on ProductRepositoryState {
  List<Product> get products;
}

class SortedProductRepositoryState extends ProductRepositoryState with ResultState {
  SortedProductRepositoryState(this.products, {required Sort super.sort, required SortField super.sortField});

  @override
  final List<Product> products;

  @override
  bool get isLoading => false;
}

class FilteredProductRepositoryState extends ProductRepositoryState with ResultState {
  FilteredProductRepositoryState(this.products, {required Filter super.filter});

  @override
  final List<Product> products;

  @override
  bool get isLoading => false;
}

class AllProductRepositoryState extends ProductRepositoryState with ResultState {
  AllProductRepositoryState(this.products);

  @override
  final List<Product> products;

  @override
  bool get isLoading => false;
}

class LoadingProductRepositoryState extends ProductRepositoryState {
  LoadingProductRepositoryState({super.filter, super.sort, super.sortField});

  @override
  bool get isLoading => true;
}

class IdleProductRepositoryState extends ProductRepositoryState {
  @override
  bool get isLoading => false;
}

class ProductRepository extends Bloc<ProductRepositoryEvent, ProductRepositoryState> {
  ProductRepository() : super(IdleProductRepositoryState()) {
    on<FilterEvent>(_onFilterEvent);
    on<SortEvent>(_onSortEvent);
    on<RemoveOrderEvent>(_onRemoveOrderEvent);
    on<LoadEvent>(_onLoadEvent);
    on<RefreshEvent>(_onRefreshEvent);
  }

  void _onFilterEvent(FilterEvent event, Emitter<ProductRepositoryState> emit) async {
    emit(LoadingProductRepositoryState(filter: event.filter));
    var list = await API.getFilteredProducts(event.filter);
    emit(FilteredProductRepositoryState(list, filter: event.filter));
  }

  void _onSortEvent(SortEvent event, Emitter<ProductRepositoryState> emit) async {
    emit(LoadingProductRepositoryState(sort: event.sort, sortField: event.sortField));
    var list = await API.getSorted(event.sortField, event.sort);
    emit(SortedProductRepositoryState(list, sort: event.sort, sortField: event.sortField));
  }

  void _onRemoveOrderEvent(RemoveOrderEvent event, Emitter<ProductRepositoryState> emit) async {
    emit(LoadingProductRepositoryState());
    var list = await API.getAllProducts();
    emit(AllProductRepositoryState(list));
  }

  void _onLoadEvent(LoadEvent event, Emitter<ProductRepositoryState> emit) async {
    var list = await API.getAllProducts();
    emit(AllProductRepositoryState(list));
  }

  void _onRefreshEvent(RefreshEvent event, Emitter<ProductRepositoryState> emit) async {
    if (state is FilteredProductRepositoryState) {
      add(FilterEvent(state.filter!));
    } else if (state is SortedProductRepositoryState) {
      add(SortEvent(state.sortField!, state.sort!));
    } else {
      add(LoadEvent());
    }
  }
}

class API {
  static Future<List<Product>> getAllProducts() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.generate(50, (index) => Product(id: index, price: Random().nextInt(20000)))..shuffle();
  }

  static Future<List<Product>> getFilteredProducts(Filter filter) async {
    await Future.delayed(const Duration(seconds: 1));
    final list = List.generate(50, (index) => Product(id: index, price: Random().nextInt(20000)))..shuffle();
    return list.where((e) => filter == Filter.even ? e.id.isEven : e.id.isOdd).toList();
  }

  static Future<List<Product>> getSorted(SortField sortField, Sort sort) async {
    await Future.delayed(const Duration(seconds: 1));
    final list = List.generate(50, (index) => Product(id: index, price: Random().nextInt(20000)))..shuffle();

    if (sortField == SortField.price) {
      if (sort == Sort.ascending) {
        list.sort((a, b) => a.price.compareTo(b.price));
      } else {
        list.sort((a, b) => b.price.compareTo(a.price));
      }
    } else {
      if (sort == Sort.ascending) {
        list.sort((a, b) => a.id.compareTo(b.id));
      } else {
        list.sort((a, b) => b.id.compareTo(a.id));
      }
    }

    return list;
  }
}

enum Filter { even, odd }

enum Sort { ascending, descending }

enum SortField { id, price }

class Product {
  const Product({required this.id, required this.price});

  final int id;
  final int price;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Product && other.id == id;
  }
}
