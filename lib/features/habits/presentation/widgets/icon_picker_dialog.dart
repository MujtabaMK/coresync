import 'package:flutter/material.dart';

class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

  static const _habitIcons = [
    '\u{1F3CB}', // weight lifting
    '\u{1F3C3}', // running
    '\u{1F6B6}', // walking
    '\u{1F6B4}', // cycling
    '\u{1F3CA}', // swimming
    '\u{1F9D8}', // meditation
    '\u{1F4DA}', // books
    '\u{1F4D6}', // reading
    '\u{270D}',  // writing
    '\u{1F4A7}', // water drop
    '\u{1F34E}', // apple
    '\u{1F957}', // salad
    '\u{1F4A4}', // sleep
    '\u{1F6CC}', // bed
    '\u{2615}',  // coffee
    '\u{1F9F9}', // broom
    '\u{1F3B5}', // music
    '\u{1F3B8}', // guitar
    '\u{1F3A8}', // art palette
    '\u{1F4BB}', // laptop
    '\u{1F4F1}', // phone
    '\u{1F48A}', // pill
    '\u{1F9E0}', // brain
    '\u{1F5E3}', // speaking
    '\u{1F9D1}\u{200D}\u{1F4BB}', // technologist
    '\u{1F4B0}', // money bag
    '\u{1F3AF}', // target
    '\u{2B50}',  // star
    '\u{1F525}', // fire
    '\u{2764}',  // heart
    '\u{1F331}', // seedling
    '\u{1F343}', // leaf
  ];

  static const _emojiList = [
    '\u{1F600}', '\u{1F601}', '\u{1F602}', '\u{1F923}', '\u{1F60A}',
    '\u{1F60E}', '\u{1F929}', '\u{1F970}', '\u{1F60D}', '\u{1F618}',
    '\u{1F4AA}', '\u{1F44D}', '\u{1F44F}', '\u{1F64C}', '\u{270C}',
    '\u{1F91E}', '\u{1F919}', '\u{1F448}', '\u{1F449}', '\u{1F446}',
    '\u{1F436}', '\u{1F431}', '\u{1F43B}', '\u{1F42F}', '\u{1F981}',
    '\u{1F984}', '\u{1F40D}', '\u{1F422}', '\u{1F41F}', '\u{1F419}',
    '\u{1F33B}', '\u{1F337}', '\u{1F339}', '\u{1F33A}', '\u{1F340}',
    '\u{1F334}', '\u{1F332}', '\u{1F335}', '\u{1F344}', '\u{1F33F}',
    '\u{1F349}', '\u{1F34D}', '\u{1F34C}', '\u{1F353}', '\u{1F352}',
    '\u{1F347}', '\u{1F351}', '\u{1F34B}', '\u{1F350}', '\u{1F95D}',
    '\u{26BD}', '\u{1F3C0}', '\u{1F3C8}', '\u{26BE}', '\u{1F3BE}',
    '\u{1F3D0}', '\u{1F3B3}', '\u{1F3CF}', '\u{1F3D2}', '\u{1F94A}',
    '\u{2708}', '\u{1F680}', '\u{1F697}', '\u{1F6B2}', '\u{1F6F4}',
    '\u{1F30D}', '\u{1F30E}', '\u{1F30F}', '\u{2B50}', '\u{1F31F}',
    '\u{1F308}', '\u{2600}', '\u{1F324}', '\u{26C5}', '\u{1F327}',
    '\u{1F3E0}', '\u{1F3EB}', '\u{1F3E5}', '\u{1F3EA}', '\u{1F3ED}',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        title: const Text('Pick an Icon'),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
        content: SizedBox(
          width: 320,
          height: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Habit Icons'),
                  Tab(text: 'Emojis'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGrid(context, _habitIcons),
                    _buildGrid(context, _emojiList),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<String> icons) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pop(context, icons[index]),
          child: Center(
            child: Text(
              icons[index],
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      },
    );
  }
}
