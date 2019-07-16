import 'package:flutter/material.dart';
import 'package:sms_maintained/sms.dart';
import 'package:contacts_service/contacts_service.dart';
import 'dart:async';
import 'package:simple_permissions/simple_permissions.dart';

void main() => runApp(ContactsApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broadcast SMS',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Broadcast SMS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ContactsService contactsService = new ContactsService();
  Iterable<Contact> contacts;// = main()._uiCustomContacts;


  void _showDialog(String message) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Notice"),
          content: new Text(message),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _sendSMS(Contact contact) {
    _showDialog(contact.phones
        .toList()
        .elementAt(0)
        .value);
    SmsSender().sendSms(SmsMessage(contact.phones
        .toList()
        .elementAt(0)
        .value, "Broadcast SMS"));
  }

  void _loopThru() {
    contacts.forEach(_sendSMS);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,

          children: <Widget>[
            TextField(

            ),
            RaisedButton(
              onPressed: _loopThru,
              child: Text(
                  'Send',
                  style: TextStyle(fontSize: 20)
              ),
            ),
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
  class ContactsApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
  return new MaterialApp(
  title: 'Broadcast SMS',
  theme: new ThemeData(
  primarySwatch: Colors.blue,
  ),
  home: new ContactHomePage(title: 'Contact Selection'),
  );
  }
  }
  class ContactHomePage extends StatefulWidget {
  ContactHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final String reloadLabel = 'Reload!';
  final String fireLabel = 'Select Contacts';
  final Color floatingButtonColor = Colors.red;
  final IconData reloadIcon = Icons.refresh;
  final IconData fireIcon = Icons.filter_center_focus;

  @override
  _ContactHomePageState createState() => new _ContactHomePageState(
    floatingButtonLabel: this.fireLabel,
    icon: this.fireIcon,
    floatingButtonColor: this.floatingButtonColor,
  );
  }
class _ContactHomePageState extends State<ContactHomePage> {
  List<Contact> _contacts = new List<Contact>();
  List<CustomContact> _uiCustomContacts = List<CustomContact>();
  List<CustomContact> _allContacts = List<CustomContact>();
  bool _isLoading = false;
  String floatingButtonLabel;
  Color floatingButtonColor;
  IconData icon;

  _ContactHomePageState({
  this.floatingButtonLabel,
  this.icon,
  this.floatingButtonColor,
  });

  @override
  void initState() {
  super.initState();
  getContactsPermission().then((granted) {
  if (granted) {
  refreshContacts();
  } else {
  showDialog(
  context: context,
  builder: (context) => AlertDialog(
  title: const Text('Oops!'),
  content: const Text('Looks like permission to read contacts is not granted.'),
  actions: <Widget>[
  FlatButton(
  child: const Text('OK'),
  onPressed: () => Navigator.pop(context),
  ),
  ],
  ),
  );
  }
  });
  }

  @override
  Widget build(BuildContext context) {
  return new Scaffold(
  appBar: new AppBar(
  title: new Text(widget.title),
  ),
  body: !_isLoading
  ? Container(
  child: ListView.builder(
  itemCount: _uiCustomContacts?.length,
  itemBuilder: (BuildContext context, int index) {
  CustomContact _contact = _uiCustomContacts[index];
  var _phonesList = _contact.contact.phones.toList();

  return _buildListTile(_contact, _phonesList);
  },
  ),
  )
      : Center(
  child: CircularProgressIndicator(),
  ),
  floatingActionButton: new FloatingActionButton.extended(
  backgroundColor: floatingButtonColor,
  onPressed: _onSubmit,
  icon: Icon(icon),
  label: Text(floatingButtonLabel),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );
  }

  void _onSubmit() {
  _uiCustomContacts =
  _allContacts.where((contact) => contact.isChecked == true).toList();
  runApp(MyApp());
  }

  ListTile _buildListTile(CustomContact c, List<Item> list) {
  return ListTile(
  leading: (c.contact.avatar != null)
  ? CircleAvatar(backgroundImage: MemoryImage(c.contact.avatar))
      : CircleAvatar(
  child: Text(
  (c.contact.displayName[0] +
  c.contact.displayName[1].toUpperCase()),
  style: TextStyle(color: Colors.white)),
  ),
  title: Text(c.contact.displayName ?? ""),
  subtitle: list.length >= 1 && list[0]?.value != null
  ? Text(list[0].value)
      : Text(''),
  trailing: Checkbox(
  activeColor: Colors.green,
  value: c.isChecked,
  onChanged: (bool value) {
  setState(() {
  c.isChecked = value;
  });
  }),
  );
  }

  refreshContacts() async {
  setState(() {
  _isLoading = true;
  });
  var contacts = await ContactsService.getContacts();
  _populateContacts(contacts);
  }

  void _populateContacts(Iterable<Contact> contacts) {
  _contacts = contacts.where((item) => item.displayName != null).toList();
  _contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
  _allContacts =
  _contacts.map((contact) => CustomContact(contact: contact)).toList();
  setState(() {
  _uiCustomContacts = _allContacts;
  _isLoading = false;
  });
  }

  Future<bool> getContactsPermission() =>
  SimplePermissions.checkPermission(Permission.ReadContacts);
  }

  class CustomContact {
  final Contact contact;
  bool isChecked;

  CustomContact({
  this.contact,
  this.isChecked = false,
  });
  }
