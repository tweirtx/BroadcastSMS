import 'dart:async';

import 'package:broadcast_sms/showdialog.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:sms_maintained/sms.dart';
import 'package:fluttertoast/fluttertoast.dart';



void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Broadcast SMS',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Contact Selection'),
    );
  }

}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final String fireLabel = 'Select contacts';
  final Color floatingButtonColor = Colors.blue;
  final IconData fireIcon = Icons.filter_center_focus;

  @override
  _MyHomePageState createState() => new _MyHomePageState(
    floatingButtonLabel: this.fireLabel,
    icon: this.fireIcon,
    floatingButtonColor: this.floatingButtonColor,
  );
}

class _MyHomePageState extends State<MyHomePage> {
  List<Contact> _contacts = new List<Contact>();
  List<CustomContact> _uiCustomContacts = List<CustomContact>();
  List<CustomContact> _allContacts = List<CustomContact>();
  bool _isLoading = false;
  String floatingButtonLabel;
  Color floatingButtonColor;
  IconData icon;

  _MyHomePageState({
    this.floatingButtonLabel,
    this.icon,
    this.floatingButtonColor,
  });

  @override
  void initState() {
    super.initState();
    getContactsPermission().then((granted) {
      if (granted == PermissionStatus.authorized) {
        refreshContacts();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Oops!'),
            content: const Text('Looks like permission to read contacts is not granted. Please restart the app and grant permission.'),
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
      Navigator.push(
        context,
        new MaterialPageRoute(builder: (context) => new SendScreen(
          contacts: _uiCustomContacts,
        )),
      );
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

  Future<PermissionStatus> getContactsPermission() =>
      SimplePermissions.requestPermission(Permission.ReadContacts);
}

class CustomContact {
  final Contact contact;
  bool isChecked;

  CustomContact({
    this.contact,
    this.isChecked = false,
  });
}
class SendScreen extends StatefulWidget {
  final List<CustomContact> contacts;
  SendScreen({this.contacts});
  @override
  _SendScreenState createState() => new _SendScreenState(contacts: contacts);


}
class _SendScreenState extends State<SendScreen> {
  final List<CustomContact> contacts;
  _SendScreenState({this.contacts});
  TextEditingController messageField = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Broadcast SMS"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[TextField(
            controller: messageField,
            maxLines: null,
          ),
            RaisedButton(
              onPressed: _textContacts,
              child: Text(
                  'Send',
                  style: TextStyle(fontSize: 20)
              ),
            ),
            RaisedButton(
              onPressed: _sendEmojiTest,
              child: Text(
                'Send Emoji Test'
            ),
            )
          ],
        ),
      ),
    );
  }
  void _sendEmojiTest() {
    SmsMessage smsMessage = new SmsMessage('5125458529', "");
    SmsSender().sendSms(smsMessage);
  }
  void _sendIt(CustomContact contact) {
    if (contact.isChecked) {
      SmsMessage msg = new SmsMessage(contact.contact.phones
          .toList()
          .elementAt(0)
          .value
          .toString(), messageField.text);
      SmsSender().sendSms(msg);
    }
  }
  void _textContacts() {
    int contactSendCount = 0;
    for (CustomContact contact in contacts) {
      if (contact.isChecked) {
        contactSendCount++;
      }
    }
    if (contactSendCount == 0) {
      dialogShower().presentDialog("No contacts selected. Please select at least one contact and try again.", context);
      return;
    }
    getSmsPermission().then((granted) {
      if (granted == PermissionStatus.authorized) {
        _toast("Sending...");
        contacts.forEach(_sendIt);
        _toast("Messages sent!");
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Oops!'),
            content: const Text('Looks like permission to send SMS is not granted. Please allow Broadcast SMS to send SMS.'),
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
  void _toast(String msg) {
    Fluttertoast.showToast(msg: msg);
  }
  Future<PermissionStatus> getSmsPermission() =>
      SimplePermissions.requestPermission(Permission.SendSMS);
}
