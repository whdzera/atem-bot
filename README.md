<img align="center" width="150" src="https://i.imgur.com/Fgolqn1.png" />

![Lang](https://img.shields.io/badge/language-ruby-red)
![Lang](https://img.shields.io/badge/language-typescript-blue)

# Atem Bot
discord, Telegram, and Whatsapp bot for search yugioh card, written in ruby and typescript.

### Play

> Discord : https://top.gg/bot/617492380710469763

> Telegram : https://t.me/Atem_YugiohBot

> Whatsapp : -


### Usage

|   Commands    |    Discord    |    Telegram    |    Whatsapp    |
| ------------- | ------------- | ------------- | ------------- |
| information  | ```/info``` | ```/info``` | ```:atem``` |
| ping | ```/ping``` | ```/ping``` | ```:ping``` |
| random card | ```/random``` | ```/random``` | ```:random``` |
| list card  |  ```/list```    | ```/list``` | ```:list```|
| image card  |  ```/art```    | ```/card``` | ```/card```|
| search card | ```/search``` | ```/search``` | ```:search``` |
| quick search card | ```::card_name::``` | ```::card_name::``` | ```::card_name::``` |

### View

![](https://i.imgur.com/QcedrlV.png)

<img align="center" width="350" src="https://i.imgur.com/SS9VM9L.gif" />

### Prerequisite
- Ruby 2.7.0 up
- Node 18.20.8 up

install all dependency

```
bundle install && npm install
```

### Running and Tools

Run Discord bot only
```
rake run dc=yes     
```

Run WhatsApp and Telegram bots
```
rake run wa=yes tele=yes  
```

Run all bots
```
rake run dc=yes wa=yes tele=yes  
```

kill process bot
```
rake kill
```

unit test 
 ```
 rake test
 ```
## Contributing

1. Fork the repository.
2. Create a new branch: `git checkout -b feature-branch`
3. Make your changes and commit them: `git commit -m 'Add new feature'`
4. Push to the branch: `git push origin feature-branch`
5. Create a pull request.

## License

This project is licensed under the Apache License.

## Contact

For any questions or suggestions, feel free to open an issue on GitHub.
