/// User domain types and role checking

pub type UserId =
  String

pub type Role {
  Admin
  Regular
}

pub type User {
  User(id: UserId, role: Role)
}

pub fn is_admin(user: User) -> Bool {
  case user.role {
    Admin -> True
    Regular -> False
  }
}
