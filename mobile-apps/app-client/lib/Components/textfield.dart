import 'package:flutter/material.dart';

class EntryField extends StatelessWidget {
  final String? label;
  final String? title;
  const EntryField(this.label, this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        label != null
            ? Row(
                children: [
                  Text(
                    label!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 12),
                  ),
                ],
              )
            : SizedBox.shrink(),
        TextFormField(
          decoration: InputDecoration(
              prefixStyle: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Colors.black),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              hintText: title,
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.black, fontSize: 17)),
        ),
      ],
    );
  }
}

class SmallTextFormField extends StatelessWidget {
  final String? label;
  final String? title;
  const SmallTextFormField(this.label, this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        label != null
            ? Row(
                children: [
                  Text(
                    label!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 11),
                  ),
                ],
              )
            : SizedBox.shrink(),
        TextFormField(
          decoration: InputDecoration(
              isDense: true,
              prefixStyle: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Colors.black),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              hintText: title,
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.black, fontSize: 14)),
        ),
        SizedBox(
          height: 15,
        )
      ],
    );
  }
}

class SmallImageTextFormField extends StatelessWidget {
  final String img;
  final String label;
  final String title;
  const SmallImageTextFormField(this.img, this.label, this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style:
                  Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 11),
            ),
          ],
        ),
        TextFormField(
          decoration: InputDecoration(
              isDense: true,
              prefixStyle: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Colors.black),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              hintText: title,
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.black, fontSize: 14)),
        ),
        SizedBox(
          height: 15,
        )
      ],
    );
  }
}
