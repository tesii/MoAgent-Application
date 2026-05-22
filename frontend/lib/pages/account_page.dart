import 'dart:async';
import 'package:flutter/material.dart';
import 'package:user_management/main.dart';
import 'api_service.dart'; // Ensure this file has the methods to call your API

class UserRegistrationForm extends StatefulWidget {
  @override
  _UserRegistrationFormState createState() => _UserRegistrationFormState();
}

class _UserRegistrationFormState extends State<UserRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  String _username = '';
  String _fullname = '';
  String _password = '';
  String? _role;
  List<String> _selectedProvinces = [];
  List<String> _selectedDistricts = [];
  List<String> _selectedSectors = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<String> roles = ['SRM', 'RM', 'Channel', 'TDR'];
  List<String> _provinces = [];
  Map<String, List<String>> _provinceDistricts = {};
  Map<String, List<String>> _districtSectors = {};
  List<String> _allDistricts = [];
  List<String> _allSectors = [];
  List<String> _franchiseIds = [];
  String _concatenatedFranchiseIds = '';

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    setState(() => _isLoading = true);
    try {
      _provinces = await _userService.fetchProvinces();
      _provinceDistricts.clear();
      for (var province in _provinces) {
        List<String> districts = await _userService.fetchDistricts(province);
        _provinceDistricts[province] = districts;
        _allDistricts.addAll(districts);
      }
      _allDistricts = _allDistricts.toSet().toList();
      _districtSectors.clear();
      for (var district in _allDistricts) {
        List<String> sectors = await _userService.fetchSectors(district);
        _districtSectors[district] = sectors;
        _allSectors.addAll(sectors);
      }
      _allSectors = _allSectors.toSet().toList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFranchiseIds(String location) async {
    setState(() => _isLoading = true);
    try {
      List<String> franchiseIds = await _userService.fetchFranchiseMsisdnHash(location);
      if (franchiseIds.isEmpty) {
        throw Exception('No franchise IDs found for the selected location.');
      }
      setState(() {
        _franchiseIds = franchiseIds;
        _concatenatedFranchiseIds = _franchiseIds.join(', ');
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _franchiseIds.clear();
        _concatenatedFranchiseIds = '';
        _errorMessage = 'Failed to fetch franchise IDs: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    } else if (value.length < 5) {
      return 'Username must be at least 5 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    } else if (value.length < 5) {
      return 'Password must be at least 5 characters';
    }
    return null;
  }
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState?.save();
      String location = _determineLocation();
      if (_franchiseIds.isEmpty) {
        await _fetchFranchiseIds(location);
      }
      if (_franchiseIds.isEmpty) {
        setState(() {
          _errorMessage = 'No valid franchise IDs to submit.';
        });
        return;
      }
      String franchiseIdsForSubmission = _franchiseIds.join(', ');
      try {
        String responseMessage = await _userService.createAccount(
          _username,
          _fullname,
          _password,
          _role!,
          location,
          franchiseIdsForSubmission,
        );
        bool success = responseMessage.toLowerCase().contains('success');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'User registered successfully!' : responseMessage)),
        );
        if (success) {
          _formKey.currentState?.reset();
          setState(() {
            _franchiseIds.clear();
            _concatenatedFranchiseIds = '';
            _selectedProvinces.clear();
            _selectedDistricts.clear();
            _selectedSectors.clear();
            _role = null;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Registration error: $e';
        });
      }
    }
  }

  String _determineLocation() {
    switch (_role) {
      case 'SRM':
        return _selectedProvinces.join(', ');
      case 'RM':
        List<String> locations = [];
        locations.addAll(_selectedProvinces);
        locations.addAll(_selectedDistricts);
        return locations.join(', ');
      case 'Channel':
        List<String> locations = [];
        locations.addAll(_selectedDistricts);
        locations.addAll(_selectedSectors);
        return locations.join(', ');
      case 'TDR':
        return _selectedSectors.join(', ');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: _buildFormContainer(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLogo(),
            _buildTitle(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 20),
            _buildUsernameField(),
            _buildFullNameField(),
            _buildPasswordField(),
            _buildRoleDropdown(),
            _buildLocationSelectors(),
            _buildFranchiseDisplay(),
            SizedBox(height: 20),
            _isLoading ? CircularProgressIndicator() : _buildRegisterButton(),
            SizedBox(height: 20),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Image.asset(
        'assets/images/mtn.PNG',
        height: 100, // Adjust the height as needed
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'User Registration',
      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      decoration: InputDecoration(
          labelText: 'Username', fillColor: Colors.yellow, filled: true
      ),
      validator: _validateUsername,
      onSaved: (value) => _username = value!,
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Full Name', fillColor: Colors.yellow, filled: true),
      validator: (value) => (value?.isEmpty ?? true) ? 'Please enter your full name' : null,
      onSaved: (value) => _fullname = value!,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      decoration: InputDecoration(
          labelText: 'Password', fillColor: Colors.yellow, filled: true
      ),
      obscureText: true,
      validator: _validatePassword,
      onSaved: (value) => _password = value!,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: 'Role', fillColor: Colors.yellow, filled: true),
      value: _role,
      onChanged: (String? newValue) {
        setState(() {
          _role = newValue;
          _selectedProvinces.clear();
          _selectedDistricts.clear();
          _selectedSectors.clear();
          _franchiseIds.clear();
          _concatenatedFranchiseIds = '';
        });
      },
      items: roles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(role, style: TextStyle(color: Colors.black)),
        );
      }).toList(),
      validator: (value) => (value == null) ? 'Please select a role' : null,
    );
  }

  Widget _buildLocationSelectors() {
    if (_role == null) return Container();

    switch (_role) {
      case 'SRM':
        return _buildProvinceCheckboxes();
      case 'RM':
        return _buildRMLocationSelectors();
      case 'Channel':
        return _buildChannelLocationSelectors();
      case 'TDR':
        return _buildTDRLocationSelectors();
      default:
        return Container();
    }
  }

  Widget _buildProvinceCheckboxes() {
    return Column(
      children: [
        Text('Select Provinces', style: TextStyle(color: Colors.white)),
        ..._provinces.map((province) {
          return CheckboxListTile(
            title: Text(province, style: TextStyle(color: Colors.white)),
            value: _selectedProvinces.contains(province),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  _selectedProvinces.add(province);
                } else {
                  _selectedProvinces.remove(province);
                }
                _franchiseIds.clear();
                _concatenatedFranchiseIds = '';
              });
            },
          );
        }).toList(),
        ElevatedButton(
          onPressed: _selectedProvinces.isEmpty
              ? null
              : () async {
            await _fetchFranchiseIds(_selectedProvinces.join(', '));
          },
          child: Text('Fetch Available Franchises'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildRMLocationSelectors() {
    return Column(
      children: [
        Text('Select Provinces and their Districts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        // Provinces selection section
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provinces:', style: TextStyle(color: Colors.white)),
              ..._provinces.map((province) {
                return CheckboxListTile(
                  title: Text(province, style: TextStyle(color: Colors.white)),
                  value: _selectedProvinces.contains(province),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedProvinces.add(province);
                      } else {
                        _selectedProvinces.remove(province);
                      }
                      _franchiseIds.clear();
                      _concatenatedFranchiseIds = '';
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),

        // Districts selection section
        if (_selectedProvinces.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Districts:', style: TextStyle(color: Colors.white)),
                ...List<Widget>.from(_selectedProvinces.expand((province) {
                  final districts = _provinceDistricts[province] ?? [];
                  return districts.map<Widget>((district) {
                    return CheckboxListTile(
                      title: Text(district, style: TextStyle(color: Colors.white)),
                      value: _selectedDistricts.contains(district),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedDistricts.add(district);
                          } else {
                            _selectedDistricts.remove(district);
                          }
                          _franchiseIds.clear();
                          _concatenatedFranchiseIds = '';
                        });
                      },
                    );
                  });
                })),
              ],
            ),
          ),

        SizedBox(height: 10),
        ElevatedButton(
          onPressed: (_selectedProvinces.isEmpty && _selectedDistricts.isEmpty)
              ? null
              : () async {
            String location = _determineLocation();
            await _fetchFranchiseIds(location);
          },
          child: Text('Fetch Available Franchises'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildChannelLocationSelectors() {
    return Column(
      children: [
        Text('Select Districts and their Sectors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        // Districts selection section
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Districts:', style: TextStyle(color: Colors.white)),
              ..._allDistricts.map((district) {
                return CheckboxListTile(
                  title: Text(district, style: TextStyle(color: Colors.white)),
                  value: _selectedDistricts.contains(district),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedDistricts.add(district);
                      } else {
                        _selectedDistricts.remove(district);
                      }
                      _franchiseIds.clear();
                      _concatenatedFranchiseIds = '';
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),

        // Sectors selection section
        if (_selectedDistricts.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sectors:', style: TextStyle(color: Colors.white)),
                ...List<Widget>.from(_selectedDistricts.expand((district) {
                  final sectors = _districtSectors[district] ?? [];
                  return sectors.map<Widget>((sector) {
                    return CheckboxListTile(
                      title: Text(sector, style: TextStyle(color: Colors.white)),
                      subtitle: Text('District: $district', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      value: _selectedSectors.contains(sector),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedSectors.add(sector);
                          } else {
                            _selectedSectors.remove(sector);
                          }
                          _franchiseIds.clear();
                          _concatenatedFranchiseIds = '';
                        });
                      },
                    );
                  });
                })),
              ],
            ),
          ),

        SizedBox(height: 10),
        ElevatedButton(
          onPressed: (_selectedDistricts.isEmpty)
              ? null
              : () async {
            String location = _determineLocation();
            await _fetchFranchiseIds(location);
          },
          child: Text('Fetch Available Franchises'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildTDRLocationSelectors() {
    return Column(
      children: [
        Text('Select Sectors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        // Sectors selection section
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Sectors:', style: TextStyle(color: Colors.white)),
              ..._allSectors.map<Widget>((sector) {
                return CheckboxListTile(
                  title: Text(sector, style: TextStyle(color: Colors.white)),
                  value: _selectedSectors.contains(sector),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedSectors.add(sector);
                      } else {
                        _selectedSectors.remove(sector);
                      }
                      _franchiseIds.clear();
                      _concatenatedFranchiseIds = '';
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),

        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectedSectors.isEmpty
              ? null
              : () async {
            await _fetchFranchiseIds(_selectedSectors.join(', '));
          },
          child: Text('Fetch Available Franchises'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildFranchiseDisplay() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Franchise IDs:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.white30)
            ),
            child: SelectableText(
              _concatenatedFranchiseIds.isNotEmpty ? _concatenatedFranchiseIds : 'No franchise IDs loaded.',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      child: Text('Register', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      },
      child: Text('Already have an account? Login', style: TextStyle(color: Colors.white)),
    );
  }
}