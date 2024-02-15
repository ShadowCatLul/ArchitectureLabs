workspace {
    name "Сервис поиска попутчиков"
    description "Архитектура сервиса по поиску попутчиков, в котором должны быть следующие требования:\
    - Пользователь (водитель) должен уметь создавать маршрут\
    - Пользователь (попутчик) должен уметь создавать поездку\
    - Водитель и попутчик могут найти друг друга по поездке и маршруту соответственно"

    !identifiers hierarchical

    model {
        properties { 
            structurizr.groupSeparator "/"
        }
        
        user_driver = person "Водитель"
        user_passenger = person "Пассажир-попутчик"

        MainService = softwareSystem "MainService" {
            description "Сервис поиска попутчиков"

            proxy = container "Proxy service" {
                description "Сервис прокси, который занимается переадресацией запросов"
            }

            client_service = container "Client Service" {
                description "Клиентский сервис, отвечающий за хранение клиентов и их особенностей."

                api = component "API" {
                    description "API сервиса"
                    technology "Go"
                    tags "API"
                }

                clients_database = component "Clients Database" {
                    description "Хранилище пользователей"
                    technology "PostgreSQL"
                    tags "database"
                }  

                api -> clients_database "Сохранение пользователей"
                clients_database -> api "Авторизация, запросы на поиск пользователей"
            }

            path_service = container "Path tracker" {
                description "Сервис трекер маршрутов и поездок"

                api = component "API" {
                    description "API сервиса"
                    technology "Go"
                    tags "API"
                }


                group "Слой хранения" {
                    route_table = component "Route table" {
                        description "Таблица всех маршрутов водителей"
                        technology "PostgreSQL"
                        tags "database"
                    }

                    travel_table = component "Travel table" {
                        description "Таблица всех поездок пользователей"
                        technology "PostgreSQL"
                        tags "database"
                    }
                }

                route_travel_searcher = component "Search worker" {
                    description "Какой-то фоновый процесс, который будет заниматься поиском попутчиков к каждому маршруту"
                    technology "Go"
                    tags "worker"
                }

                result_database = component "Result database" {
                    description "Хранение результата какому пользователю какой маршрут достался (возможен выбор)"
                    technology "Redis"
                    tags "database"
                }

                api -> route_table "Сохранение маршрутов"
                api -> travel_table "Сохранение поездок"

                route_travel_searcher -> route_table "Поиск поездок по маршрутам"
                route_travel_searcher -> travel_table "Поиск поездок по маршрутам"

                route_travel_searcher -> result_database "Соотношение id попутчика с водителями и наоборот" 

                result_database -> api "Отдача пользователю результата информации о том с кем тот едет"
            }

            proxy -> client_service "Создание пользователя, поиск пользователя, авторизация"
            client_service -> proxy "При создании/авторизации пользователя возвращается client_id"

            proxy -> path_service "Создание, получение маршрутов/поездок; отдача подключения поездок к маршруту"
            
        }

        user_driver -> MainService "API запросы от водителя в сервис и ответ"
        user_driver -> MainService.proxy "API запросы от водителя в сервис и ответ"
        user_passenger -> MainService "API запросы от пассажира в сервис и ответ"
        user_passenger -> MainService.proxy "API запросы от пассажира в сервис и ответ"



        prodution = deploymentEnvironment "Production" {
            deploymentGroup "MainService prod"

            client_service = deploymentNode "Client Services" {
                containerInstance MainService.client_service
            }

            path_service = deploymentNode "Path service" {
                containerInstance MainService.path_service
            }

            proxy = deploymentNode "Proxy" {
                containerInstance MainService.proxy
            }

            client_service -> proxy
            path_service -> proxy
        }
    }

    views {
        systemContext MainService {
            autoLayout
            include *
        }

        container MainService {
            autoLayout
            include *
        }

        component MainService.path_service {
            include *
        }

        component MainService.client_service {
            autoLayout
            include *
        }

        dynamic MainService "UC01" "Создание нового пользователя или авторизация" {
            autoLayout

            user_driver -> MainService.proxy "POST CreateUser/Authorize"
            user_passenger -> MainService.proxy "POST CreateUser/Authorize"

            MainService.proxy -> MainService.client_service "Переадресация запроса"
        }

        dynamic MainService "UC02" "Поиск пользователя по логину или маске (имя, фамилия)" {
            autoLayout

            user_driver -> MainService.proxy "GET UserByUsername/UserByFirstName"
            user_passenger -> MainService.proxy "GET UserByUsername/UserByFirstName"

            MainService.proxy -> MainService.client_service "Переадресация запроса"
        }

        dynamic MainService "UC11" "Создание маршрута/поездки" {
            autoLayout

            user_driver -> MainService.proxy "POST CreateRoute"
            user_passenger -> MainService.proxy "POST CreateTravel"
            
            MainService.proxy -> MainService.path_service "Переадресация запроса (client_id)"
        }

        dynamic MainService "UC12" "Получение маршрутов пользователя" {
            autoLayout

            user_driver -> MainService.proxy "GET UserRoute (client_id)"

            MainService.proxy -> MainService.path_service "Переадресация запроса (client_id)"
        }

        dynamic MainService "UC13" "Получение информации о поездке" {
            autoLayout

            user_driver -> MainService.proxy "GET UserTravel (client_id)"

            MainService.proxy -> MainService.path_service "Переадресация запроса (client_id)"
        }

        dynamic MainService "UC14" "Подключение пользователя к поездке" {
            autoLayout

            MainService.path_service -> MainService.proxy "Сигнал об обновлении статуса поездки"

            MainService.proxy -> user_driver  "[polling] GET UserRoute (client_id)"
            MainService.proxy -> user_passenger  "[polling] GET UserTravel (client_id)"
        }

        deployment MainService prodution {
            autoLayout
            include *
        }

        theme default
        

        styles {
            element "database" {
                shape cylinder
            }

            element "API" {
                shape Pipe
            }
        }
    }
}
