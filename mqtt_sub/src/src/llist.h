/* llist.h
 * Generic Linked List
 * Original code: https://gist.github.com/meylingtaing/11018042
 */
#ifndef GRANDPARENT_H
#define GRANDPARENT_H
struct node {
    void *data;
    struct node *next;
};

typedef struct node * llist;

/* llist_create: Create a linked list */
llist *llist_create(void *data);

/* llist_free: Free a linked list */
void llist_free(llist *list);

/* llist_free: Free a linked list, data is passed to func in the argument list before the node is freed. */
void llist_free_custom(llist *list, void (*func)(void *));


/* llist_add_inorder: Add to sorted linked list */
int llist_add_inorder(void *data, llist *list, 
                       int (*comp)(void *, void *));

/* llist_push: Add to head of list */
void llist_push(llist *list, void *data);

/* llist_pop: remove and return head of linked list */
void *llist_pop(llist *list);

/* llist_print: print linked list */
void llist_print(llist *list, void (*print)(void *data));

/* llist_getone: get item when passed function return NULL; */
void *llist_getone(llist *list, void *(*iter)(void *, void *, void *), void *param1, void* param2);
#endif