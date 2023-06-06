enum BottomTabbar {
  chats(tabIndex: 1, path: "/rooms"),
  contacts(tabIndex: 0, path: "/contactsTab"),
  stories(tabIndex: 2, path: "/stories");

  const BottomTabbar({
    required this.tabIndex,
    required this.path,
  });

  factory BottomTabbar.fromIndex(int? index) {
    switch (index) {
      case 0:
        return BottomTabbar.contacts;
      case 1:
        return BottomTabbar.chats;
      case 2: 
        return BottomTabbar.stories;
      default: 
        return BottomTabbar.chats;
    }
  }

  factory BottomTabbar.fromPath(String path) {
    if (path == chats.path) {
      return chats;
    } else if (path == contacts.path) {
      return contacts;
    } else if (path == stories.path) {
      return stories;
    }
    return chats;
  }

  final int tabIndex;

  final String path;
}