pub enum List {
    Cons(i32, Box<List>),
    Nil,
}

impl List {
    pub fn head(&self) -> Option<i32> {
        if let List::Cons(value, next) = self {
            Some(*value)
        } else {
            None
        }
    }

    pub fn tail(&self) -> Option<&List> {
        if let List::Cons(value, next) = self {
            Some(next)
        } else {
            None
        }
    }
}
