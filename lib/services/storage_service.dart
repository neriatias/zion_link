import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/apartment.dart';
import '../models/expense.dart';
import '../models/payment.dart';

class StorageService {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // return path to file
  Future<String> getFilePath() async {
    return await _localPath;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    print('$path/buildings.json');
    return File('$path/buildings.json');
  }

  // Buildings
  static Future<File> writeBuildings(List buildings) async {
    final file = await _localFile;
    return file.writeAsString(json.encode(buildings));
  }

  static Future<List> getAllBuildings() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      final List buildings = json.decode(contents) ?? [];
      // Ensure every building has a non-null list of apartments
      for (var building in buildings) {
        building['apartments'] = building['apartments'] ?? [];
      }
      return buildings;
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  static Future<void> addExpenseToBuilding(
      String buildingId, Expense newExpense) async {
    final List buildings = await getAllBuildings();
    bool found = false;
    for (var building in buildings) {
      if (building['id'] == buildingId) {
        final List expenses = building['expenses'] ?? [];
        expenses.add(
            newExpense.toJson()); // Assuming Expense class has a toJson method
        building['expenses'] = expenses;
        found = true;
        break;
      }
    }
    if (!found) {
      print("Building with ID $buildingId not found.");
    } else {
      await writeBuildings(buildings);
    }
  }

  Future<void> addPaymentToBuilding(
      String buildingId, Payment newPayment) async {
    final List buildings = await getAllBuildings();
    bool found = false;
    for (var building in buildings) {
      if (building['id'] == buildingId) {
        final List apartments = building['apartments'];
        final int apartmentIndex = apartments.indexWhere(
            (apartment) => apartment['id'] == newPayment.apartmentId);
        if (apartmentIndex != -1) {
          apartments[apartmentIndex]['payments'] =
              apartments[apartmentIndex]['payments'] ?? [];
          apartments[apartmentIndex]['payments'].add(newPayment.toJson());
        }
        found = true;
        break;
      }
    }
    if (!found) {
      print("Building with ID $buildingId not found.");
    } else {
      await writeBuildings(buildings);
    }
  }

  // Apartments
  static Future<void> updateApartment(Apartment updatedApartment) async {
    final List buildings =
        await getAllBuildings(); // Assuming this returns a list of buildings
    for (var building in buildings) {
      final List apartments = building['apartments'];
      final int index = apartments
          .indexWhere((apartment) => apartment['id'] == updatedApartment.id);
      if (index != -1) {
        apartments[index] = updatedApartment
            .toJson(); // Assuming Apartment class has a toJson method
        await writeBuildings(buildings);
        break;
      }
    }
  }

  static Future<void> writeApartment(Apartment apartment) async {
    final List buildings = await getAllBuildings();
    bool found = false;
    for (var building in buildings) {
      final List apartments = building['apartments'];
      final int index = apartments.indexWhere((a) => a['id'] == apartment.id);
      if (index != -1) {
        apartments[index] = apartment.toJson();
        found = true;
        break;
      }
    }
    if (!found) {
      // Handle case where apartment is not found in any building
      print("Apartment with ID ${apartment.id} not found.");
    } else {
      await writeBuildings(buildings);
    }
  }

  static Future<Apartment?> readApartment(String id) async {
    final List buildings = await getAllBuildings();
    for (var building in buildings) {
      final List apartments = building['apartments'];
      final index = apartments.indexWhere((apartment) => apartment['id'] == id);
      if (index != -1) {
        return Apartment.fromJson(apartments[index]);
      }
    }
    return null; // Return null if apartment with given id is not found
  }

  // Expenses
  static Future<void> updateExpense(Expense expense) async {
    final List buildings = await getAllBuildings();
    bool foundExpense = false;
    for (var building in buildings) {
      if (building['expenses'] != null) {
        final List expenses = building['expenses'];
        final int index = expenses.indexWhere((e) => e['id'] == expense.id);
        if (index != -1) {
          expenses[index] = expense.toJson();
          print("Expense updated: ${expenses[index]}");
          foundExpense = true;
          break;
        }
      }
    }
    if (!foundExpense) {
      print("Expense with ID ${expense.id} not found.");
    } else {
      await writeBuildings(buildings);
    }
  }

  static Future<void> deleteExpense(String buildingId, String expenseId) async {
    final List buildings = await getAllBuildings();
    bool foundBuilding = false;
    bool foundExpense = false;
    for (var building in buildings) {
      if (building['id'] == buildingId) {
        foundBuilding = true;
        final List expenses = building['expenses'] ?? [];
        final int index = expenses.indexWhere((e) => e['id'] == expenseId);
        if (index != -1) {
          expenses.removeAt(index);
          foundExpense = true;
          print("Expense with ID $expenseId removed.");
          break;
        }
      }
    }
    if (!foundBuilding) {
      print("Building with ID $buildingId not found.");
    } else if (!foundExpense) {
      print("Expense with ID $expenseId not found in building $buildingId.");
    } else {
      await writeBuildings(buildings);
    }
  }

  static Future<List<Expense>> readExpenses(String buildingId) async {
    final List buildings = await getAllBuildings();
    for (var building in buildings) {
      if (building['id'] == buildingId) {
        final List expensesJson = building['expenses'] ?? [];
        return expensesJson
            .map<Expense>((json) => Expense.fromJson(json))
            .toList();
      }
    }
    return []; // Return an empty list if the building or its expenses are not found
  }

  // Payments
  static Future<List<Payment>> readPayments(String buildingId) async {
    final List buildings = await getAllBuildings();
    for (var building in buildings) {
      if (building['id'] == buildingId) {
        final List paymentsJson = building['payments'] ?? [];
        return paymentsJson
            .map<Payment>((json) => Payment.fromJson(json))
            .toList();
      }
    }
    return []; // Return an empty list if the building or its payments are not found
  }

  Future<void> updatePayment(Payment updatedPayment) async {
    final List buildings = await getAllBuildings();
    bool foundPayment = false;
    for (var building in buildings) {
      final List apartments =
          building['apartments']; // Access apartments from building
      for (var apartment in apartments) {
        final List payments =
            apartment['payments'] ?? []; // Ensure payments list exists
        final int index =
            payments.indexWhere((p) => p['id'] == updatedPayment.id);
        if (index != -1) {
          payments[index] = updatedPayment.toJson();
          foundPayment = true;
          break; // Break the inner loop
        }
      }
      if (foundPayment) {
        await writeBuildings(
            buildings); // Save changes if a payment was updated
        break; // Break the outer loop
      }
    }
    if (!foundPayment) {
      print("Payment with ID ${updatedPayment.id} not found.");
    }
  }

  Future<void> deletePayment(String buildingId, String paymentId) async {
    final List buildings = await getAllBuildings();
    bool foundBuilding = false;
    bool foundPayment = false;
    for (var building in buildings) {
      if (building['id'] == buildingId) {
        foundBuilding = true;
        final List apartments = building['apartments'] ?? [];
        for (var apartment in apartments) {
          final List payments = apartment['payments'] ?? [];
          final int index = payments.indexWhere((p) => p['id'] == paymentId);
          if (index != -1) {
            payments.removeAt(index);
            foundPayment = true;
            print("Payment with ID $paymentId removed.");
            break; // Breaks out of the apartments loop once payment is found and removed
          }
        }
        if (foundPayment) {
          break; // Breaks out of the buildings loop if payment is found and removed
        }
      }
    }
    if (!foundBuilding) {
      print("Building with ID $buildingId not found.");
    } else if (!foundPayment) {
      print("Payment with ID $paymentId not found in building $buildingId.");
    } else {
      await writeBuildings(
          buildings); // Save changes only if a payment was found and removed
    }
  }
}
