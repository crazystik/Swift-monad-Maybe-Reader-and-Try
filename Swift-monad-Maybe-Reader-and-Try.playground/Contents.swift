// Functors
print("--Functors--")
enum Maybe<T> {
    case Just(T)
    case Nothing

    func fmap<U>(_ f: (T) -> U) -> Maybe<U> {
        switch self {
        case .Just(let x): return .Just(f(x))
        case .Nothing: return .Nothing
        }
    }
}
print(Maybe.Just(3).fmap { i in i+2 })
print(Maybe.Nothing.fmap { i in i+3 })

// Applicatives
print("\n--Applicatives--")

extension Maybe {
    func apply<U>(_ f: Maybe<(T) -> U>) -> Maybe<U> {
        switch f {
        case .Just(let JustF): return fmap(JustF)
        case .Nothing: return .Nothing
        }
    }
}

extension Array {
    func apply<U>(_ fs: [(Element) -> U]) -> [U] {
        fs.flatMap { map($0) }
    }
}

precedencegroup ApplicativePrecedence { associativity: left }

infix operator <*> : ApplicativePrecedence
func <*><T, U>(f: Maybe<(T) -> U>, a: Maybe<T>) -> Maybe<U> {
    a.apply(f)
}
func <*><T, U>(f: [(T) -> U], a: [T]) -> [U] {
    a.apply(f)
}

print(Maybe.Just({ $0 + 3 }) <*> Maybe.Just(2))
print([ { $0 + 3 }, { $0 * 2 } ] <*> [1, 2, 3])

//Monads
print("\n--Monads--")
func half(a: Int) -> Maybe<Int> {
    a % 2 == 0 ? Maybe.Just(a / 2) : Maybe.Nothing
}

extension Maybe {
    func flatMap<U>(_ f: (T) -> Maybe<U>) -> Maybe<U> {
        switch self {
        case .Just(let x): return f(x)
        case .Nothing: return .Nothing
        }
    }
}
infix operator >>= : ApplicativePrecedence
func >>=<T, U>(a: Maybe<T>, _ f: (T) -> Maybe<U>) -> Maybe<U> {
    a.flatMap(f)
}

print(Maybe.Just(3) >>= half)
print(Maybe.Just(4) >>= half)
print(Maybe.Nothing >>= half)
print(Maybe.Just(20) >>= half >>= half >>= half)

// Reader Monad
print("\n--Reader Monad--")
class Reader<E, A> {
    private let g: (E) -> A
    
    init(g: @escaping (E) -> A) {
        self.g = g
    }
    
    func apply(_ e: E) -> A {
        g(e)
    }
    
    func map<B>(_ f: @escaping (A) -> B) -> Reader<E, B> {
        Reader<E, B> { f(self.apply($0)) }
    }
    
    func flatMap<B>(_ f: @escaping (A) -> Reader<E, B>) -> Reader<E, B> {
        Reader<E, B>{ f(self.apply($0)).apply($0) }
    }
}

func >>=<E, A, B>(a: Reader<E, A>, f: @escaping (A) -> Reader<E, B>) -> Reader<E, B> {
    a.flatMap(f)
}

func half(i: Float) -> Reader<Float, Float> {
    Reader { $0/2 }
}

var f = Reader { $0 } >>= half //>>= half >>= half
f.apply(20) // 2.5
f.apply(20)

// Sample
struct User {
    var name: String
    var age: Int
}

struct DB {
    var path: String
    
    func findUser(_ userName: String) -> User {
        // DB Select operation
        User(name: userName, age: 29)
    }
    func updateUser(_ u: User) -> Void {
        // DB Update operation
        print(u.name + " in: " + path)
    }
}

let dbPath = "path_to_db"
func update(userName: String, newName: String) -> Void {
    let db = DB(path: dbPath)
    var user = db.findUser(userName)
    user.name = newName
    db.updateUser(user)
}
update(userName: "dummy_id", newName: "Thor")

// Dependency Injection
struct Environment {
    var path: String
}
func updateF(userName: String, newName: String) -> Reader<Environment, Void> {
    return Reader<Environment, Void>{ env in
        let db = DB(path: env.path)
        var user = db.findUser(userName)
        user.name = newName
        db.updateUser(user)
    }
}
let test = Environment(path: "path_to_sqlite")
let production = Environment(path: "path_to_realm")
updateF(userName: "dummy_id", newName: "Thor").apply(test)
updateF(userName: "dummy_id", newName: "Thor").apply(production)

// Try monad
print("\n--Try Monad--")
enum Try<T> {
    case Successful(T)
    case Failure(Error)
    
    init(f: () throws -> T) {
        do {
            self = .Successful(try f())
        } catch {
            self = .Failure(error)
        }
    }
    
    func map<U>(_ f: (T) -> U) -> Try<U> {
        switch self {
        case .Successful(let value): return .Successful(f(value))
        case .Failure(let error): return .Failure(error)
        }
    }
    
    func flatMap<U>(_ f: (T) -> Try<U>) -> Try<U> {
        switch self {
        case .Successful(let value): return f(value)
        case .Failure(let error): return .Failure(error)
        }
    }
}

enum DoomsdayComing: Error {
    case Boom
    case Bang
}

let endOfTheWorld = Try {
    throw DoomsdayComing.Bang
}

let result = Try { 4/2 }
    .flatMap { _ in endOfTheWorld }

print(result)
